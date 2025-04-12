const functions = require("firebase-functions");
const admin = require("firebase-admin");
const nodemailer = require("nodemailer");

admin.initializeApp();

// ✅ Gmail SMTP config with App Password
const transporter = nodemailer.createTransport({
  service: "gmail",
  auth: {
    user: "mohamedhammad3.142@gmail.com",
    pass: "zzvgbqyevbsgaczs", // Use your App Password, not email password
  },
});

// 🔥 Cloud Function to send OTP email
exports.sendOtpEmail = functions.firestore
    .document("otp_codes/{email}")
    .onCreate(async (snap, context) => {
      const data = snap.data();
      const email = context.params.email;

      const mailOptions = {
        from: "FoundIt <mohamedhammad3.142@gmail.com>",
        to: email,
        subject: "Your FoundIt OTP Code",
        html: `<h2>OTP Code: ${data.otp}</h2>
                    <p>This code is valid for 10 minutes.</p>`,
      };

      try {
        await transporter.sendMail(mailOptions);
        console.log("✅ OTP email sent to", email);
      } catch (error) {
        console.error("❌ Error sending OTP email:", error);
      }
    });
