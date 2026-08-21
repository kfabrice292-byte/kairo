"use strict";
var __createBinding = (this && this.__createBinding) || (Object.create ? (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    var desc = Object.getOwnPropertyDescriptor(m, k);
    if (!desc || ("get" in desc ? !m.__esModule : desc.writable || desc.configurable)) {
      desc = { enumerable: true, get: function() { return m[k]; } };
    }
    Object.defineProperty(o, k2, desc);
}) : (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    o[k2] = m[k];
}));
var __setModuleDefault = (this && this.__setModuleDefault) || (Object.create ? (function(o, v) {
    Object.defineProperty(o, "default", { enumerable: true, value: v });
}) : function(o, v) {
    o["default"] = v;
});
var __importStar = (this && this.__importStar) || (function () {
    var ownKeys = function(o) {
        ownKeys = Object.getOwnPropertyNames || function (o) {
            var ar = [];
            for (var k in o) if (Object.prototype.hasOwnProperty.call(o, k)) ar[ar.length] = k;
            return ar;
        };
        return ownKeys(o);
    };
    return function (mod) {
        if (mod && mod.__esModule) return mod;
        var result = {};
        if (mod != null) for (var k = ownKeys(mod), i = 0; i < k.length; i++) if (k[i] !== "default") __createBinding(result, mod, k[i]);
        __setModuleDefault(result, mod);
        return result;
    };
})();
Object.defineProperty(exports, "__esModule", { value: true });
exports.onUserCreated = void 0;
const functions = __importStar(require("firebase-functions"));
const admin = __importStar(require("firebase-admin"));
const firebase_functions_1 = require("firebase-functions");
const email_service_1 = require("../services/email.service");
const templates_1 = require("../emails/templates");
// Firebase Admin must be initialized in index.js before these triggers run.
exports.onUserCreated = functions.auth.user().onCreate(async (user) => {
    if (!user.email) {
        firebase_functions_1.logger.info(`L'utilisateur ${user.uid} n'a pas d'adresse e-mail.`);
        return;
    }
    const name = user.displayName || 'Cher utilisateur';
    try {
        // 1. Envoyer l'e-mail de Bienvenue
        const welcomeSuccess = await email_service_1.EmailService.sendEmail({
            to: user.email,
            subject: 'Bienvenue sur KAIRO 👋',
            html: templates_1.Templates.welcome(name)
        });
        if (welcomeSuccess) {
            firebase_functions_1.logger.info(`E-mail de bienvenue envoyé à ${user.email}`);
        }
        // 2. Si l'e-mail n'est pas vérifié, on génère un lien de vérification via Firebase Admin
        if (!user.emailVerified) {
            const actionCodeSettings = {
                // Optionnel : rediriger l'utilisateur vers l'app après vérification
                url: 'https://kairo.app/auth/verified',
                handleCodeInApp: true
            };
            const verificationLink = await admin.auth().generateEmailVerificationLink(user.email, actionCodeSettings);
            const verifySuccess = await email_service_1.EmailService.sendEmail({
                to: user.email,
                subject: 'Vérifiez votre adresse e-mail',
                html: templates_1.Templates.verifyEmail(name, verificationLink)
            });
            if (verifySuccess) {
                firebase_functions_1.logger.info(`E-mail de vérification envoyé à ${user.email}`);
            }
        }
    }
    catch (error) {
        // On logge l'erreur mais on ne fait pas planter le système
        firebase_functions_1.logger.error(`Erreur lors de l'envoi des e-mails initiaux pour ${user.uid}:`, error);
    }
});
//# sourceMappingURL=auth.triggers.js.map