import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';
import { logger } from 'firebase-functions';
import { EmailService } from '../services/email.service';
import { Templates } from '../emails/templates';

// Firebase Admin must be initialized in index.js before these triggers run.

export const onUserCreated = functions.auth.user().onCreate(async (user) => {
  if (!user.email) {
    logger.info(`L'utilisateur ${user.uid} n'a pas d'adresse e-mail.`);
    return;
  }

  const name = user.displayName || 'Cher utilisateur';

  try {
    // 1. Envoyer l'e-mail de Bienvenue
    const welcomeSuccess = await EmailService.sendEmail({
      to: user.email,
      subject: 'Bienvenue sur KAIRO 👋',
      html: Templates.welcome(name)
    });

    if (welcomeSuccess) {
      logger.info(`E-mail de bienvenue envoyé à ${user.email}`);
    }

    // 2. Si l'e-mail n'est pas vérifié, on génère un lien de vérification via Firebase Admin
    if (!user.emailVerified) {
      const actionCodeSettings = {
        // Optionnel : rediriger l'utilisateur vers l'app après vérification
        url: 'https://kairo.app/auth/verified', 
        handleCodeInApp: true
      };

      const verificationLink = await admin.auth().generateEmailVerificationLink(user.email, actionCodeSettings);

      const verifySuccess = await EmailService.sendEmail({
        to: user.email,
        subject: 'Vérifiez votre adresse e-mail',
        html: Templates.verifyEmail(name, verificationLink)
      });

      if (verifySuccess) {
        logger.info(`E-mail de vérification envoyé à ${user.email}`);
      }
    }
  } catch (error) {
    // On logge l'erreur mais on ne fait pas planter le système
    logger.error(`Erreur lors de l'envoi des e-mails initiaux pour ${user.uid}:`, error);
  }
});
