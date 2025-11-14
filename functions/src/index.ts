// functions/src/index.ts
import * as logger from "firebase-functions/logger";
import {onRequest} from "firebase-functions/v2/https";
import {onObjectFinalized} from "firebase-functions/v2/storage";
import {initializeApp} from "firebase-admin/app";
import {getStorage} from "firebase-admin/storage";
import {getFirestore} from "firebase-admin/firestore";
import * as xlsx from "xlsx";
import * as mammoth from "mammoth";

// Inicializáljuk az Admin SDK-t
initializeApp();
const db = getFirestore("sws-ai-database"); // A te adatbázisod neve

// === searchKnowledgeBase (HTTP Trigger) ===
// Ez az a funkció, amit a Flutter appod hív.
export const searchKnowledgeBase = onRequest(
  {cors: true, timeoutSeconds: 30}, // 30 mp időkorlát
  async (request, response) => {
    logger.info("searchKnowledgeBase funkció meghívva",
      {structuredData: true});

    const query = request.query.query as string;
    if (query == null || query === "") {
      response.status(400).json({"error":
        "Keresési kifejezés megadása kötelező"});
      return;
    }

    // A Vector Search bővítmény ezt a kollekciót figyeli
    const queryCollectionPath = "firestore-vector-search/index/queries";

    try {
      // 1. Létrehozunk egy "kérdés" dokumentumot a bővítménynek
      const queryDocRef = await db.collection(queryCollectionPath).add({
        query: query, // A felhasználó kérdése
        status: "pending", // Állapot
      });

      // 2. Várunk a válaszra...
      const results = await new Promise((resolve, reject) => {
        const unsubscribe = queryDocRef.onSnapshot(
          (snapshot) => {
            const data = snapshot.data();
            // 3. Ellenőrizzük, megjött-e a válasz
            if (data && data.status === "complete" && data.results) {
              unsubscribe();
              resolve(data.results);
            } else if (data && data.status === "error") {
              unsubscribe();
              reject(new Error(data.errorMessage || "A bővítmény hibát adott"));
            }
          },
          (error) => {
            unsubscribe();
            reject(error);
          },
        );

        // Időkorlát
        setTimeout(() => {
          unsubscribe();
          reject(new Error("A keresés időtúllépéses (30s)."));
        }, 30000);
      });

      // 4. Formázzuk a választ
      const topResult = (results as any[])?.[0];

      if (topResult && topResult.document) {
        const responseData = {
          "source_document": topResult.document.filePath || "Ismeretlen fájl",
          "content_snippet": topResult.document.text || "Nincs szövegrészlet",
          "confidence": topResult.distance,
        };
        response.json(responseData);
      } else {
        // Ha nem talált semmit
        response.json({
          "source_document": "nincs_találat",
          "content_snippet":
            "Nem találtam releváns információt a feltöltött dokumentumokban.",
          "confidence": 0.0,
        });
      }
    } catch (error) {
      const errorMessage = error instanceof Error ?
        error.message : "Ismeretlen hiba";
      logger.error("Hiba a 'searchKnowledgeBase' futása közben:", errorMessage);
      response.status(500).json({error: errorMessage});
    }
  },
);

// === processDocument (Storage Trigger) ===
// Ez az a funkció, ami a fájlfeltöltéskor fut le.
export const processDocument = onObjectFinalized(async (event) => {
  const fileBucket = event.data.bucket;
  const filePath = event.data.name;

  if (!filePath) {
    logger.warn("Nincs fájlút, a funkció leáll.");
    return;
  }

  const bucket = getStorage().bucket(fileBucket);
  const file = bucket.file(filePath);
  const [fileBuffer] = await file.download();

  logger.info(`Fájl letöltve: ${filePath}`);

  let extractedText = "";

  try {
    if (filePath.endsWith(".xlsx")) {
      const workbook = xlsx.read(fileBuffer, {type: "buffer"});
      const sheetName = workbook.SheetNames[0];
      const worksheet = workbook.Sheets[sheetName];
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
    logger.info("Szöveg kinyerve, mentés a Firestore " +
      "'knowledge_base' kollekciójába...");
    await db.collection("knowledge_base").add({
      text: extractedText,
      filePath: filePath,
      createdAt: new Date(),
    });
    logger.info(`Sikeres mentés a Firestore-ba: ${filePath}`);
  } catch (error) {
    logger.error(`Hiba a fájl feldolgozása közben: ${filePath}`, error);
  }
});
