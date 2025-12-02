package utils

import (
	"fmt"
)

func GetOTPEmailBody(otp string) string {
	// Simple, professional HTML template
	return fmt.Sprintf(`
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <style>
        body {
            font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
            background-color: #f4f4f4;
            margin: 0;
            padding: 0;
            color: #333333;
        }
        .container {
            max-width: 600px;
            margin: 40px auto;
            background-color: #ffffff;
            border-radius: 8px;
            box-shadow: 0 4px 8px rgba(0,0,0,0.05);
            overflow: hidden;
        }
        .header {
            background-color: #2c3e50;
            padding: 30px;
            text-align: center;
        }
        .header h1 {
            color: #ffffff;
            margin: 0;
            font-size: 24px;
            font-weight: 600;
        }
        .content {
            padding: 40px 30px;
            text-align: center;
        }
        .otp-box {
            background-color: #f0f4f8;
            border: 1px dashed #2c3e50;
            border-radius: 4px;
            padding: 15px 30px;
            font-size: 32px;
            font-weight: bold;
            letter-spacing: 5px;
            color: #2c3e50;
            display: inline-block;
            margin: 20px 0;
        }
        .footer {
            background-color: #f9f9f9;
            padding: 20px;
            text-align: center;
            font-size: 12px;
            color: #888888;
            border-top: 1px solid #eeeeee;
        }
        .footer p {
            margin: 5px 0;
        }
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <h1>Swift Transit</h1>
        </div>
        <div class="content">
            <p style="font-size: 16px; margin-bottom: 20px;">Hello,</p>
            <p style="font-size: 16px; line-height: 1.5;">Use the One-Time Password (OTP) below to complete your verification.</p>
            
            <div class="otp-box">%s</div>
            
            <p style="font-size: 14px; color: #666666; margin-top: 20px;">This OTP is valid for 10 minutes. Do not share this code with anyone.</p>
        </div>
        <div class="footer">
            <p>&copy; 2025 Swift Transit. All rights reserved.</p>
            <p>If you did not request this email, please ignore it.</p>
        </div>
    </div>
</body>
</html>
`, otp)
}
