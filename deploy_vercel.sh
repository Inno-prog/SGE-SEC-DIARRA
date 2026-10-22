#!/bin/bash
set -e

echo "=========================================="
echo "🚀 Déploiement SGE Secdiarra Web sur Vercel"
echo "=========================================="

# 1. Détection de Flutter
FLUTTER_BIN="flutter"
if ! command -v flutter &> /dev/null; then
  if [ -f "$HOME/development/flutter/bin/flutter" ]; then
    FLUTTER_BIN="$HOME/development/flutter/bin/flutter"
  else
    echo "❌ Flutter n'a pas été trouvé. Assurez-vous qu'il est installé et dans votre PATH."
    exit 1
  fi
fi

echo "📦 1. Compilation de l'application Flutter Web en mode Release..."
$FLUTTER_BIN build web --release

# S'assurer que vercel.json est bien présent dans build/web
if [ ! -f "build/web/vercel.json" ]; then
  cp web/vercel.json build/web/vercel.json 2>/dev/null || cp vercel.json build/web/vercel.json
fi

echo "🌐 2. Déploiement sur Vercel..."
if command -v vercel &> /dev/null; then
  vercel deploy --prod build/web
elif command -v npx &> /dev/null; then
  npx vercel --prod build/web
else
  echo "❌ Vercel CLI n'est pas installé. Installez-le avec : npm install -g vercel"
  exit 1
fi

echo "=========================================="
echo "✅ Déploiement terminé avec succès !"
echo "⚠️ N'oubliez pas d'ajouter le domaine Vercel dans Firebase Console > Authentication > Paramètres > Domaines autorisés !"
echo "=========================================="

