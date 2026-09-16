import { Resend } from 'resend';
import { logger } from 'firebase-functions';

// Initialize Resend. We use a fallback just in case, but it should come from process.env
// The API key is ONLY accessible on the server.
const resendApiKey = process.env.RESEND_API_KEY;
const resend = new Resend(resendApiKey || 'dummy_key');

const DEFAULT_FROM = 'KAIRO <kairo@agencegenio.com>';

export interface SendEmailOptions {
  to: string | string[];
  subject: string;
  html: string;
  replyTo?: string;
}

export class EmailService {
  /**
   * Envoie un e-mail transactionnel avec gestion des erreurs et retries (idempotence au niveau réseau).
   * L'idempotence métier (ex: emailSent = true) doit être gérée par l'appelant.
   */
  static async sendEmail(options: SendEmailOptions, maxRetries = 2): Promise<boolean> {
    if (!resendApiKey) {
      logger.error('RESEND_API_KEY is not defined in environment variables.');
      return false;
    }

    let attempt = 0;
    while (attempt <= maxRetries) {
      try {
        const { data, error } = await resend.emails.send({
          from: DEFAULT_FROM,
          to: options.to,
          subject: options.subject,
          html: options.html,
          replyTo: options.replyTo,
        });

        if (error) {
          throw new Error(`Resend Error: ${error.message} (Code: ${error.name})`);
        }

        logger.info(`Email successfully sent to ${options.to}. Resend ID: ${data?.id}`);
        return true;
      } catch (err: any) {
        attempt++;
        logger.error(`Attempt ${attempt} - Failed to send email to ${options.to}:`, err.message);
        
        if (attempt <= maxRetries) {
          // Wait before retrying (exponential backoff)
          await new Promise(resolve => setTimeout(resolve, attempt * 1000));
        }
      }
    }

    logger.error(`Failed to send email to ${options.to} after ${maxRetries + 1} attempts.`);
    return false;
  }
}
