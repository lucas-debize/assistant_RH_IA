CREATE TABLE IF NOT EXISTS offre_emploi (
    id SERIAL PRIMARY KEY,
    titre VARCHAR(255) NOT NULL,
    description TEXT NOT NULL,
    competences_requises JSONB DEFAULT '[]'::jsonb,
    active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS candidatures (
    id SERIAL PRIMARY KEY,
    message_id VARCHAR(512) UNIQUE,
    email_expediteur VARCHAR(255) NOT NULL,
    sujet_email VARCHAR(500),
    date_reception TIMESTAMP WITH TIME ZONE,
    nom_fichier_cv VARCHAR(500),
    texte_cv TEXT,
    resume_candidat TEXT,
    competences JSONB DEFAULT '[]'::jsonb,
    score_compatibilite INTEGER CHECK (score_compatibilite >= 0 AND score_compatibilite <= 100),
    points_forts JSONB DEFAULT '[]'::jsonb,
    points_faibles JSONB DEFAULT '[]'::jsonb,
    analyse_complete JSONB,
    offre_emploi_id INTEGER REFERENCES offre_emploi(id),
    date_traitement TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    statut VARCHAR(50) DEFAULT 'traite'
);

CREATE INDEX IF NOT EXISTS idx_candidatures_email ON candidatures(email_expediteur);
CREATE INDEX IF NOT EXISTS idx_candidatures_score ON candidatures(score_compatibilite DESC);
CREATE INDEX IF NOT EXISTS idx_candidatures_date ON candidatures(date_traitement DESC);

INSERT INTO offre_emploi (titre, description, competences_requises, active)
VALUES (
    'Développeur Full Stack',
    'Nous recherchons un développeur Full Stack pour rejoindre notre équipe produit.
     Missions : développement d''applications web (React, Node.js), intégration d''APIs,
     participation aux revues de code, collaboration avec l''équipe UX.
     Profil : 2+ ans d''expérience, autonomie, bon relationnel, anglais technique.',
    '["JavaScript", "TypeScript", "React", "Node.js", "PostgreSQL", "Docker", "Git", "API REST"]'::jsonb,
    TRUE
);
