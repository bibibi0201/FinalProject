/************************************************************
 * Posture Monitoring System with Buzzer Alert
 * ----------------------------------------------------------
 * ระบบตรวจจับท่านั่งด้วย MPU6050 และส่งข้อมูลขึ้น Firebase
 * พร้อมแจ้งเตือนผ่าน Buzzer เมื่อผู้ใช้นั่งผิดท่าติดต่อกัน 3 รอบ
 
 * Main Features:
  - อ่านค่าการเอียงจาก MPU6050
  - คำนวณ Pitch / Roll ด้วย Complementary Filter
  - รองรับ Calibration ผ่าน Firebase
  - บันทึกค่า Calibration ลง Flash Memory
  - ส่งข้อมูลขึ้น Firebase ทุก 15 วินาที
  - แจ้งเตือนผ่าน Buzzer เมื่อ posture incorrect 3 ครั้งติด
 ************************************************************/
 
#include <Wire.h>
#include <MPU6050.h>
#include <WiFi.h>
#include <Firebase_ESP_Client.h>
#include <time.h>
#include <Preferences.h>

#include <addons/TokenHelper.h>
#include <addons/RTDBHelper.h>

/************************************************************
 * WiFi Configuration
 * ใช้สำหรับเชื่อมต่ออินเทอร์เน็ตเพื่อส่งข้อมูลขึ้น Firebase
 ************************************************************/
const char* ssid = "gold_gear_66_2.4G";
const char* password = "572572572";

/************************************************************
 * Firebase Configuration
 * ใช้เชื่อมต่อ Firebase Realtime Database
 * URL และ API ได้จากการที่เราสร้าง Project ใน Firebase
 ************************************************************/
#define DATABASE_URL "https://project-93e75-default-rtdb.asia-southeast1.firebasedatabase.app/" 
#define API_KEY      "AIzaSyBEv0Zx2q9ljs6n-fjvBt4jxfcblzmWze0"
#define USER_EMAIL    "esp32@test.com"
#define USER_PASSWORD "12345678"

/************************************************************
 * Device 
 * ใช้เป็นชื่อ Node หลักของบอร์ดนี้ใน Firebase 
 * ตั้งชื่อบอร์ดและบอร์ดตัวนี้จะถูกสร้างเป็น node ใน Firebase
 ************************************************************/
#define BOARD_ID "test001"s

#define BUZZER_PIN 18 // ขา buzzer

FirebaseData fbdo;
FirebaseAuth auth;
FirebaseConfig config;
Preferences preferences;

MPU6050 mpu;

/************************************************************
 * Calibration Variables
 * ใช้เก็บค่า Reference ตอนผู้ใช้นั่งตรงครั้งแรก
 ************************************************************/
float pitch0 = 0.0, roll0 = 0.0;
bool calibrated = false;

float pitch = 0.0, old_pitch = 0.0;
unsigned long lastCalcTime = 0;
unsigned long lastSendTime = 0;
unsigned long lastCalCheck = 0;

#define SEND_INTERVAL      15000  // ส่งข้อมูลทุก 15 วินาที
#define CAL_CHECK_INTERVAL 10000  // เช็ค calibration request ทุก 10 วินาที

/************************************************************
 * Incorrect Posture Counter
 * ใช้นับจำนวนครั้งที่นั่งผิดติดกัน
 ************************************************************/
int incorrectCount = 0;

/************************************************************
 * SETUP FUNCTION
 * ทำงานเพียงครั้งเดียวตอนเปิดเครื่อง
 ************************************************************/
void setup() {

  Serial.begin(115200);
  Wire.begin();   // เริ่มต้น I2C Communication
  mpu.initialize();

/******************************************************
  * ตั้งค่า Buzzer Output
  * Active LOW:
  * LOW = ดัง
  * HIGH = ปิด
******************************************************/
  pinMode(BUZZER_PIN, OUTPUT);
  digitalWrite(BUZZER_PIN, HIGH);

/******************************************************
   * โหลดค่า Calibration เดิมจาก Flash Memory กรณีหลุดหรือเชื่อมต่อใหม่มันจะยังจำค่าที่เรา Calibration ไว้ตอนแรก
******************************************************/
  preferences.begin(BOARD_ID, false);
  calibrated = preferences.getBool("isCal", false); 

  if (calibrated) {
    pitch0 = preferences.getFloat("p0", 0.0);         
    roll0  = preferences.getFloat("r0", 0.0);
    Serial.println(">>> Calibration Restored <<<");
  }
  preferences.end();

/******************************************************
   * เชื่อมต่อ WiFi
******************************************************/
  WiFi.begin(ssid, password);
  while (WiFi.status() != WL_CONNECTED) {
    delay(500);
    Serial.print(".");
  }

  Serial.println("\nWiFi Connected");

/******************************************************
   * Sync เวลาจาก NTP Server
   * ใช้สำหรับ timestamp ตอนบันทึกข้อมูล
******************************************************/
  configTime(7 * 3600, 0, "pool.ntp.org");

  struct tm timeinfo;
  while (!getLocalTime(&timeinfo)) delay(500);

/******************************************************
   * Firebase Authentication Setup
******************************************************/
  config.api_key = API_KEY;
  config.database_url = DATABASE_URL;
  config.token_status_callback = tokenStatusCallback;

  auth.user.email = USER_EMAIL;
  auth.user.password = USER_PASSWORD;

/******************************************************
   * เริ่มต้น Firebase
 ******************************************************/
  Firebase.begin(&config, &auth);
  Firebase.reconnectWiFi(true);

  delay(1000);

/******************************************************
  * สร้าง Calibration Node ถ้ายังไม่มีใน Firebase
******************************************************/
  String calBasePath = String("/") + BOARD_ID + "/calibration";

  if (!Firebase.RTDB.getJSON(&fbdo, calBasePath.c_str())) {

    FirebaseJson initCal;
    initCal.set("pitch0", 0);
    initCal.set("roll0", 0);
    initCal.set("request", false);

    Firebase.RTDB.setJSON(&fbdo, calBasePath.c_str(), &initCal);

    Serial.println("Created calibration node in Firebase");
  }

  lastCalcTime = millis();
}

void loop() {
  
   /******************************************************
   * อ่านค่าดิบจาก MPU6050
   ******************************************************/
  int16_t ax, ay, az, gx, gy, gz;
  mpu.getMotion6(&ax, &ay, &az, &gx, &gy, &gz);

  /******************************************************
   * คำนวณ Delta Time สำหรับ Integrate Gyro
   ******************************************************/
  unsigned long now = millis();
  float dt = (now - lastCalcTime) / 1000.0;
  lastCalcTime = now;

  if (dt <= 0 || dt > 1) dt = 0.01;

 /******************************************************
   * คำนวณ Pitch ด้วย Complementary Filter
   * รวมข้อดีของ Accelerometer + Gyroscope
   ******************************************************/
  float accPitch = atan2(ax, sqrt(pow(ay, 2) + pow(az, 2))) * 180.0 / PI;
  pitch = 0.98 * (old_pitch + (gx / 131.0) * dt) + 0.02 * accPitch;
  old_pitch = pitch;

  /******************************************************
   * คำนวณ Roll จาก Accelerometer
   ******************************************************/
  float roll = atan2(ay, sqrt(pow(ax, 2) + pow(az, 2))) * 180.0 / PI;

  /******************************************************
   * CHECK Calibration Request from Firebase กรณีผู้ใช้ส่ง request มา request เป็น true จะทำการบันทึกค่า calibration ไว้แล้ว reset request=false
   ******************************************************/
  if (Firebase.ready() && millis() - lastCalCheck > CAL_CHECK_INTERVAL) {

    lastCalCheck = millis();

    String calPath = String("/") + BOARD_ID + "/calibration/request";

    if (Firebase.RTDB.getBool(&fbdo, calPath.c_str()) && fbdo.boolData()) {
      /******************************************
       * Save Current Posture as New Calibration
       ******************************************/
      pitch0 = pitch;
      roll0 = roll;
      calibrated = true;
      /******************************************
       * Save Calibration ลง Flash Memory
       ******************************************/
      preferences.begin(BOARD_ID, false);
      preferences.putFloat("p0", pitch0);
      preferences.putFloat("r0", roll0);
      preferences.putBool("isCal", true);
      preferences.end();
      /******************************************
       * Update Firebase Calibration Data
       ******************************************/
      FirebaseJson cal;
      cal.set("pitch0", pitch0);
      cal.set("roll0", roll0);
      cal.set("request", false);

      String updatePath = String("/") + BOARD_ID + "/calibration";
      Firebase.RTDB.updateNode(&fbdo, updatePath.c_str(), &cal);

      Serial.println(">> New Calibration Saved <<");
    }
  }
 /******************************************************
   * ส่งข้อมูลขึ้น Firebase ทุก SEND_INTERVAL
  ******************************************************/
  if (Firebase.ready() && millis() - lastSendTime > SEND_INTERVAL) {

    lastSendTime = millis();

    struct tm t;
    if (!getLocalTime(&t)) return;

    /**************************************************
     * Format Date/Time String (ส่งข้อมูลตามวันเวลา)
     **************************************************/
    char dS[11], tS[9];
    strftime(dS, 11, "%Y-%m-%d", &t);
    strftime(tS, 9, "%H-%M-%S", &t);

    /**************************************************
     * Calculate Delta from Calibration Point
     * คำนวณความต่างของมุมว่าการนั่งต่างจากเดิมไหม
     **************************************************/
    float dP = calibrated ? pitch - pitch0 : 0;
    float dR = calibrated ? roll - roll0 : 0;

    String posture = "unknown";
    String detail = "";

    if (!calibrated) {
      posture = "unknown";
      detail = "ยังไม่ได้ปรับเทียบ";
    }

    else {

      bool isCorrect = true;
      /******************************************
       * ตรวจจับท่านั่งผิดจาก Threshold
       ******************************************/
      if (dP < -20) {
        detail += "ก้มมากไป,";
        isCorrect = false;
      }

      else if (dP > 20) {
        detail += "เงยมากไป,";
        isCorrect = false;
      }

      if (dR < -10) {
        detail += "เอียงซ้ายมากไป,";
        isCorrect = false;
      }

      else if (dR > 10) {
        detail += "เอียงขวามากไป,";
        isCorrect = false;
      }

      if (detail.endsWith(",")) {
        detail.remove(detail.length() - 1);
      }

      posture = isCorrect ? "correct" : "incorrect";

      /******************************************
       * Buzzer Logic
       * ถ้านั่งผิดครบ 3 รอบติด ให้แจ้งเตือน
       ******************************************/
      if (!isCorrect) {

        incorrectCount++;

        Serial.print("Incorrect Count: ");
        Serial.println(incorrectCount);

        if (incorrectCount >= 3) {

          digitalWrite(BUZZER_PIN, LOW);
          delay(1000);
          digitalWrite(BUZZER_PIN, HIGH);

          incorrectCount = 0;
        }
      }

      else {
        incorrectCount = 0;
      }

      if (isCorrect) {
        detail = "ท่านั่งปกติ";
      }
    }
    /**************************************************
     * Prepare JSON for Firebase Upload ข้อมูลที่จะส่งขึ้น Firebase
     **************************************************/
    FirebaseJson json;

    json.set("pitch", pitch);
    json.set("roll", roll);
    json.set("deltaPitch", dP);
    json.set("deltaRoll", dR);
    json.set("posture", posture);
    json.set("postureDetail", detail);


    /**************************************************
     * ข้อมูลที่เตรียมไว้จะส่งไปเก็บไว้ใน node History
     **************************************************/
    String path = String("/") + BOARD_ID + "/history/" + String(dS) + "/" + String(tS);

    if (Firebase.RTDB.setJSON(&fbdo, path.c_str(), &json)) {

      Serial.println("Upload OK");
    }

    else {

      Serial.println("Upload FAILED");
      delay(500);
      ESP.restart();
    }
  }
}