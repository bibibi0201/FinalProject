#include <Wire.h>
#include <MPU6050.h>
#include <WiFi.h>
#include <Firebase_ESP_Client.h>
#include <time.h>
#include <Preferences.h>

#include <addons/TokenHelper.h>
#include <addons/RTDBHelper.h>

// WiFi 
const char* ssid = "gold_gear_66_2.4G";
const char* password = "572572572";

// Firebase 
#define DATABASE_URL "https://project-93e75-default-rtdb.asia-southeast1.firebasedatabase.app/"
#define API_KEY      "AIzaSyBEv0Zx2q9ljs6n-fjvBt4jxfcblzmWze0"
#define USER_EMAIL    "esp32@test.com"
#define USER_PASSWORD "12345678"

#define BOARD_ID "esp03"

FirebaseData fbdo;
FirebaseAuth auth;
FirebaseConfig config;
Preferences preferences;

MPU6050 mpu;

float pitch0 = 0.0, roll0 = 0.0;
bool calibrated = false;

float pitch = 0.0, old_pitch = 0.0;
unsigned long lastCalcTime = 0;
unsigned long lastSendTime = 0;
unsigned long lastCalCheck = 0;

#define SEND_INTERVAL      15000
#define CAL_CHECK_INTERVAL 10000

void setup() {

  Serial.begin(115200);
  Wire.begin();
  mpu.initialize();

  // โหลด Calibration จาก memory (แยกตาม BOARD_ID)
  preferences.begin(BOARD_ID, false);
  calibrated = preferences.getBool("isCal", false);

  if (calibrated) {
    pitch0 = preferences.getFloat("p0", 0.0);
    roll0  = preferences.getFloat("r0", 0.0);
    Serial.println(">>> Calibration Restored <<<");
  }
  preferences.end();

  WiFi.begin(ssid, password);
  while (WiFi.status() != WL_CONNECTED) {
    delay(500);
    Serial.print(".");
  }
  Serial.println("\nWiFi Connected");

  configTime(7 * 3600, 0, "pool.ntp.org");
  struct tm timeinfo;
  while (!getLocalTime(&timeinfo)) delay(500);

  config.api_key = API_KEY;
  config.database_url = DATABASE_URL;
  config.token_status_callback = tokenStatusCallback;

  auth.user.email = USER_EMAIL;
  auth.user.password = USER_PASSWORD;

  Firebase.begin(&config, &auth);
  Firebase.reconnectWiFi(true);

  delay(1000);

  // ถ้าไม่มี node calibration ให้สร้าง
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

  // ===== อ่านค่า MPU =====
  int16_t ax, ay, az, gx, gy, gz;
  mpu.getMotion6(&ax, &ay, &az, &gx, &gy, &gz);

  unsigned long now = millis();
  float dt = (now - lastCalcTime) / 1000.0;
  lastCalcTime = now;
  if (dt <= 0 || dt > 1) dt = 0.01;

  float accPitch = atan2(ax, sqrt(pow(ay, 2) + pow(az, 2))) * 180.0 / PI;
  pitch = 0.98 * (old_pitch + (gx / 131.0) * dt) + 0.02 * accPitch;
  old_pitch = pitch;

  float roll = atan2(ay, sqrt(pow(ax, 2) + pow(az, 2))) * 180.0 / PI;

  // ตรวจสอบคำสั่ง Calibration จากแอพที่กดปุ่ม Calibration
  if (Firebase.ready() && millis() - lastCalCheck > CAL_CHECK_INTERVAL) {

    lastCalCheck = millis();

    String calPath = String("/") + BOARD_ID + "/calibration/request";

    if (Firebase.RTDB.getBool(&fbdo, calPath.c_str()) && fbdo.boolData()) {

      pitch0 = pitch;
      roll0  = roll;
      calibrated = true;

      preferences.begin(BOARD_ID, false);
      preferences.putFloat("p0", pitch0);
      preferences.putFloat("r0", roll0);
      preferences.putBool("isCal", true);
      preferences.end();

      FirebaseJson cal;
      cal.set("pitch0", pitch0);
      cal.set("roll0", roll0);
      cal.set("request", false);

      String updatePath = String("/") + BOARD_ID + "/calibration";
      Firebase.RTDB.updateNode(&fbdo, updatePath.c_str(), &cal);

      Serial.println(">> New Calibration Saved <<");
    }
  }

  // ส่งข้อมูลให้ Firebase 
  if (Firebase.ready() && millis() - lastSendTime > SEND_INTERVAL) {

    lastSendTime = millis();

    struct tm t;
    if (!getLocalTime(&t)) return;
  // ds = ข้อมูลวัน Y-M-D, ts = ข้อมูลเวลา
    char dS[11], tS[9];
    strftime(dS, 11, "%Y-%m-%d", &t);
    strftime(tS, 9, "%H-%M-%S", &t);

    float dP = calibrated ? pitch - pitch0 : 0;
    float dR = calibrated ? roll  - roll0  : 0;

    String posture = "unknown";
    String detail  = "";

    if (!calibrated) {
      posture = "unknown";
      detail  = "ยังไม่ได้ปรับเทียบ";
    }
    else {

      bool isCorrect = true;

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

      if (isCorrect) {
        detail = "ท่านั่งปกติ";
      }
    }

    FirebaseJson json;
    json.set("pitch", pitch);
    json.set("roll", roll);
    json.set("deltaPitch", dP);
    json.set("deltaRoll", dR);
    json.set("posture", posture);
    json.set("postureDetail", detail);

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