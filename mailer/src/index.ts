import {S3} from 'aws-sdk';
import {SNSEvent} from 'aws-lambda';
import nodemailer from 'nodemailer';

const s3 = new S3();

exports.handler = async (event: SNSEvent) => {
    // Generate a signed URL for the S3 object
    const signedUrl = s3.getSignedUrl('getObject', {
        Bucket: process.env.S3_BUCKET_NAME,
        Key: process.env.S3_OBJECT_KEY,
        Expires: 60 * 60 * 24 // URL expiration time in seconds (e.g., 1 day)
    });

    // populate email options
    // recipient email address, json with single key 'email'
    const recipientEmail = event.Records[0].Sns.MessageAttributes['email'].Value
    const obfuscatedEmail = recipientEmail.replace(/(.{2}).+(@.+)/, '$1***$2')
    const mailOptions = {
        from: `"Mike" ${process.env.FROM_EMAIL}`,
        to: recipientEmail,
        subject: 'Resume Request',
        html: `
        <p>Greetings!</p>
        <p>Click <strong><a href=\"${signedUrl}\">here</a></strong> to view my current resume. Please note this url will expire in 24 hours.</p>
        </br>
        <p>If you are unable to view this url, please contact me at ${process.env.FROM_EMAIL} for assistance.</p>
        <br/><p>Best,<br/>Mike</p>
        `
    };

    // Create a transporter using Gmail
    const transporter = nodemailer.createTransport({
        service: 'gmail',
        auth: {
            user: process.env.FROM_EMAIL,
            pass: process.env.FROM_PASSWORD
        }
    });

    try {
        // Send the email using nodemailer
        await transporter.sendMail(mailOptions);
        console.log(`Email sent successfully to ${obfuscatedEmail}.`);
    } catch (error) {
        console.error(`Error sending email to ${obfuscatedEmail}:`, error);
        throw error;
    }
};
