// functions/src/index.ts
import * as logger from "firebase-functions/logger";
// Importáljuk a HTTP kéréseket kezelő funkciót
import {onRequest} from "firebase-functions/v2/https";

// Ez a mi "dummy" kereső funkciónk, HTTP-n keresztül hívható
export const searchKnowledgeBase = onRequest(
  {cors: true}, // Automatikus CORS kezelés (ez a helyes v2-es mód)
  (request, response) => {
    logger.info("searchKnowledgeBase funkció meghívva", {structuredData: true});

    // 1. Olvassuk ki a keresési szöveget az URL-ből (pl. ...?query=kovacs)
    const query = request.query.query as string;

    // 2. Készítsük elő a "dummy" választ
    let resultData = {};

    if (query == null || query === "") {
      resultData = {"error": "Keresési kifejezés megadása kötelező"};
    } else if (query.toLowerCase().includes("kovács") &&
               query.toLowerCase().includes("bónusz")) {
      resultData = {
        "source_document": "bonuszok_2023.xlsx",
        "content_snippet":
           "Kovács János (IT Osztály) 2023-as bónusza: 500,000 Ft. " +
          "Kifizetve: 2024.01.10.",
        "confidence": 0.95,
      };
    } else {
      resultData = {
        "source_document": "nincs_találat",
        "content_snippet":
          "A keresett információ nem található a dokumentumokban.",
        "confidence": 0.0,
      };
    }

    // 3. Küldjük vissza a választ JSON formátumban
    response.json(resultData);
  },
);
