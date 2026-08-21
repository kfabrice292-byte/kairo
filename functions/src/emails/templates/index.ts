/**
 * Génère la structure de base d'un e-mail KAIRO
 */
const baseEmailTemplate = (content: string, preheader: string = 'Message de KAIRO') => `
<!DOCTYPE html>
<html lang="fr">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>KAIRO</title>
  <style>
    body {
      font-family: 'Inter', -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif;
      background-color: #f5f5f5;
      margin: 0;
      padding: 0;
      color: #333333;
    }
    .container {
      max-width: 600px;
      margin: 40px auto;
      background-color: #ffffff;
      border-radius: 8px;
      overflow: hidden;
      box-shadow: 0 4px 12px rgba(0, 0, 0, 0.05);
    }
    .header {
      background-color: #ffffff;
      padding: 30px;
      text-align: center;
      border-bottom: 1px solid #eeeeee;
    }
    .header h1 {
      margin: 0;
      color: #0A0A0A;
      font-size: 28px;
      letter-spacing: -0.5px;
    }
    .content {
      padding: 40px 30px;
      line-height: 1.6;
    }
    .content h2 {
      color: #111111;
      font-size: 20px;
      margin-top: 0;
    }
    .btn {
      display: inline-block;
      padding: 12px 24px;
      background-color: #000000;
      color: #ffffff !important;
      text-decoration: none;
      border-radius: 6px;
      font-weight: 600;
      margin: 20px 0;
    }
    .footer {
      background-color: #fafafa;
      padding: 20px 30px;
      text-align: center;
      font-size: 13px;
      color: #888888;
      border-top: 1px solid #eeeeee;
    }
  </style>
</head>
<body>
  <span style="display:none;font-size:1px;color:#333333;line-height:1px;max-height:0px;max-width:0px;opacity:0;overflow:hidden;">${preheader}</span>
  <div class="container">
    <div class="header">
      <h1>KAIRO</h1>
    </div>
    <div class="content">
      ${content}
    </div>
    <div class="footer">
      &copy; ${new Date().getFullYear()} KAIRO — Agence Genio.<br>
      Tous droits réservés.
    </div>
  </div>
</body>
</html>
`;

export const Templates = {
  welcome: (name: string) => baseEmailTemplate(`
    <h2>Bienvenue sur KAIRO 👋</h2>
    <p>Bonjour ${name},</p>
    <p>Nous sommes ravis de vous compter parmi nous. KAIRO est la plateforme de mise en relation de talents et d'opportunités, propulsée par le matching intelligent.</p>
    <p>Complétez votre profil dès maintenant pour découvrir les opportunités qui vous correspondent.</p>
    <div style="text-align: center;">
      <a href="https://kairo.app" class="btn">Accéder à KAIRO</a>
    </div>
  `, 'Bienvenue sur KAIRO, complétez votre profil dès aujourd\'hui !'),

  verifyEmail: (name: string, link: string) => baseEmailTemplate(`
    <h2>Vérifiez votre adresse e-mail</h2>
    <p>Bonjour ${name},</p>
    <p>Merci de vous être inscrit sur KAIRO. Afin de sécuriser votre compte et de profiter pleinement de nos services, veuillez confirmer votre adresse e-mail en cliquant sur le bouton ci-dessous :</p>
    <div style="text-align: center;">
      <a href="${link}" class="btn">Vérifier mon e-mail</a>
    </div>
    <p style="font-size: 12px; color: #666;">Ce lien expirera prochainement. Si vous n'êtes pas à l'origine de cette demande, vous pouvez ignorer cet e-mail.</p>
  `, 'Action requise : vérifiez votre adresse e-mail KAIRO'),

  applicationSubmitted: (name: string, opportunityTitle: string, companyName: string) => baseEmailTemplate(`
    <h2>Votre candidature a bien été envoyée</h2>
    <p>Bonjour ${name},</p>
    <p>Nous vous confirmons la bonne réception de votre candidature pour le poste de <strong>${opportunityTitle}</strong> chez <strong>${companyName}</strong>.</p>
    <p>L'équipe de recrutement étudiera votre profil dans les plus brefs délais.</p>
    <div style="text-align: center;">
      <a href="https://kairo.app/applications" class="btn">Suivre ma candidature</a>
    </div>
  `, `Confirmation de candidature pour ${opportunityTitle}`),

  newApplication: (recruiterName: string, candidateName: string, opportunityTitle: string) => baseEmailTemplate(`
    <h2>Vous avez reçu une nouvelle candidature</h2>
    <p>Bonjour ${recruiterName},</p>
    <p>Bonne nouvelle ! <strong>${candidateName}</strong> vient de postuler à votre opportunité : <strong>${opportunityTitle}</strong>.</p>
    <p>Connectez-vous à votre espace recruteur pour consulter son profil et traiter cette candidature.</p>
    <div style="text-align: center;">
      <a href="https://kairo.app/recruiter/pipeline" class="btn">Consulter la candidature</a>
    </div>
  `, `Nouvelle candidature de ${candidateName} pour ${opportunityTitle}`),

  applicationAccepted: (name: string, opportunityTitle: string, companyName: string) => baseEmailTemplate(`
    <h2>Bonne nouvelle 🎉 Votre candidature a été retenue</h2>
    <p>Bonjour ${name},</p>
    <p>Suite à l'étude de votre profil, l'entreprise <strong>${companyName}</strong> a le plaisir de vous annoncer que votre candidature pour le poste de <strong>${opportunityTitle}</strong> a été retenue !</p>
    <p>Le recruteur vous contactera très prochainement pour la suite du processus.</p>
    <div style="text-align: center;">
      <a href="https://kairo.app/applications" class="btn">Voir les détails</a>
    </div>
  `, `Excellente nouvelle ! Votre candidature chez ${companyName} avance.`),

  applicationRejected: (name: string, opportunityTitle: string, companyName: string) => baseEmailTemplate(`
    <h2>Mise à jour concernant votre candidature</h2>
    <p>Bonjour ${name},</p>
    <p>Nous vous remercions pour l'intérêt que vous avez porté à l'opportunité <strong>${opportunityTitle}</strong> chez <strong>${companyName}</strong>.</p>
    <p>Malgré la qualité de votre profil, l'entreprise ne donnera malheureusement pas suite à votre candidature pour le moment.</p>
    <p>Nous vous encourageons à mettre à jour votre profil KAIRO pour maximiser vos chances sur vos prochaines candidatures.</p>
  `, `Mise à jour de votre candidature chez ${companyName}`),

  opportunityMatch: (name: string, opportunityTitle: string, companyName: string, score: number) => baseEmailTemplate(`
    <h2>Une opportunité pourrait vous intéresser</h2>
    <p>Bonjour ${name},</p>
    <p>Notre algorithme KAIRO a identifié une correspondance exceptionnelle (${score}% de compatibilité) entre votre profil et une nouvelle opportunité !</p>
    <p>L'entreprise <strong>${companyName}</strong> recrute actuellement pour le poste de <strong>${opportunityTitle}</strong>.</p>
    <p>N'attendez plus, découvrez cette offre en exclusivité :</p>
    <div style="text-align: center;">
      <a href="https://kairo.app/opportunities" class="btn">Voir l'opportunité</a>
    </div>
  `, `Découvrez l'offre de ${opportunityTitle} qui matche avec votre profil !`)
};
