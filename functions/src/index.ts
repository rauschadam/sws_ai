// functions/src/index.ts
import * as logger from "firebase-functions/logger";
import {onRequest} from "firebase-functions/v2/https"; // HTTP trigger
import {onObjectFinalized} from "firebase-functions/v2/storage";
import {initializeApp} from "firebase-admin/app"; // Admin SDK
import {getStorage} from "firebase-admin/storage"; // Admin Storage
import * as xlsx from "xlsx";
import * as mammoth from "mammoth";

// Inicializáljuk az Admin SDK-t (egyszer kell, a fájl tetején)
initializeApp();

// HTTP Trigger ezt hívja a Flutter app
export const searchKnowledgeBase = onRequest(
  {cors: true},
  (request, response) => {
    logger.info("searchKnowledgeBase funkció meghívva", {structuredData: true});
    const query = request.query.query as string;
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
    response.json(resultData);
  },
);

// === Storage Trigger ===
// Ez a funkció automatikusan lefut, ha BÁRMILYEN fájlt
// feltöltesz a Firebase Storage-be.
export const processDocument = onObjectFinalized(async (event) => {
  const fileBucket = event.data.bucket;
  const filePath = event.data.name;

  // Kilép ha nincs elérési út
  if (!filePath) {
    logger.warn("Nincs fájlút, a funkció leáll.");
    return;
  }

  // Töltsük le a fájlt a memóriába (buffer-be)
  const bucket = getStorage().bucket(fileBucket);
  const file = bucket.file(filePath);
  const [fileBuffer] = await file.download();

  logger.info(`Fájl letöltve: ${filePath}`);

  let extractedText = "";

  try {
    // 1. Megpróbáljuk Excel-ként olvasni (.xlsx)
    if (filePath.endsWith(".xlsx")) {
      const workbook = xlsx.read(fileBuffer, {type: "buffer"});
      const sheetName = workbook.SheetNames[0];
      const worksheet = workbook.Sheets[sheetName];
      // Átalakítjuk a munkalapot egyszerű szöveggé (CSV formátum)
      extractedText = xlsx.utils.sheet_to_csv(worksheet);
      logger.info("Excel fájl sikeresen feldolgozva.");
    } else if (filePath.endsWith(".docx")) {
      const result = await mammoth.extractRawText({buffer: fileBuffer});
      extractedText = result.value;
      logger.info("Word fájl sikeresen feldolgozva.");
    } else {
      logger.warn(`Nem támogatott fájltípus: ${filePath}`);
      return;
    }

    // Kiírjuk a kinyert szöveg elejét a logba
    logger.info(`A kinyert szöveg eleje (${filePath}):`,
      extractedText.substring(0, 500) // Csak az első 500 karaktert
    );

    // === KÖVETKEZŐ LÉPÉS (Később) ===
    // 1. Darabold (Chunk) a 'extractedText'-et
    // 2. Vektorizáld a darabokat
    // 3. Mentsd el a Vektor Adatbázisba
  } catch (error) {
    logger.error(`Hiba a fájl feldolgozása közben: ${filePath}`, error);
  }
});
