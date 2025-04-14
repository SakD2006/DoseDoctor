# 💊 Dose Doctor

**Dose Doctor** is the doctor-side companion app for the **Dose Dost** ecosystem. It enables doctors to efficiently manage prescriptions and patient data by connecting directly to the patient's profile through a simple QR scan.

---

## 📱 What is Dose Doctor?

Dose Doctor is a Flutter-based mobile application designed for healthcare professionals. It works seamlessly with the patient-side app **Dose Dost** to provide a connected, real-time prescription system.

### 🔗 Dose Doctor allows doctors to:
- 🔍 Scan a patient's QR code to instantly connect to their profile.
- 🧾 Create and manage prescriptions directly in the app.
- 💾 Push prescribed medicines and dosage info to the patient’s personal database.
- 🖨️ Print or review the prescription as needed.

---

## 🧩 Dependencies

- This app is **dependent on [Dose Dost](https://github.com/SakD2006/dosedost.git)** – the patient-side app that manages reminders, logs, and medicine intake schedules.
- Firebase for authentication and real-time database operations.
- QR Scanner functionality to fetch patient UID and connect to their database.

---

## 🚀 Getting Started

### Prerequisites

- Flutter SDK
- Firebase project setup (with Firestore or Realtime DB)
- Android Studio or VS Code

### Installation
1. **Using this command**
    ```bash
    git clone https://github.com/SakD2006/dose_doctor.git
    cd dose-doctor
    flutter pub get
    flutter run

---

## ✨ Features

- Clean and responsive UI built with Flutter
- Firebase integration for user management and data sync
- Dynamic QR code scanning and database linking
- Editable prescription form with multiple medication entries
- Save + Print functionality post-submission

---

## 🛠️ Future Enhancements

- Add support for attaching lab reports and notes
- Integration with pharmacy inventory
- Push notification system for medicine instructions

---

## 📣 Note

This app is not standalone — it works in tandem with the Dose Dost app which handles patient-side features like reminders and tracking.

---

## TEAM

**BigBoyCoders**
- Saksham 24BBS0081
- Aryaman 24BBS0110
- Prakyath 24BBS0079
- Devarsh 24BBS0153
- Tanay 24BBS0104
