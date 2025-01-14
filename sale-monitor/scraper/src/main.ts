import { PlaywrightCrawler } from 'crawlee';

import { GoogleGenerativeAI, SchemaType } from "@google/generative-ai";

import express from 'express';

/*
 * Crawler
 */

const googleAIAPIKey = process.env.GOOGLE_AI_API_KEY;

if (!googleAIAPIKey) {
    throw new Error("GOOGLE_AI_API_KEY is not set");
}

const genAI = new GoogleGenerativeAI(googleAIAPIKey);

const schema = {
    type: SchemaType.OBJECT,
    description: "Product price and sale information",
    properties: {
        error: {
            type: SchemaType.STRING,
            description: "Error message if the product price or sale information is not found",
        },
        result: {
            type: SchemaType.OBJECT,
            description: "Result of the product price and sale information if successful",
            properties: {
                price: {
                    type: SchemaType.NUMBER,
                    description: "Price of the product",
                },
                is_sale: {
                    type: SchemaType.BOOLEAN,
                    description: "Whether the product is on sale",
                },
                pre_sale_price: {
                    type: SchemaType.NUMBER,
                    description: "Reported price of the product before the sale",
                    nullable: true,
                },
            },
            required: ["price", "is_sale", "pre_sale_price"],
        },
    },
    required: [],
};

const model = genAI.getGenerativeModel({
    model: "gemini-2.0-flash-exp",
    generationConfig: {
        responseMimeType: "application/json",
        responseSchema: schema
    }
});

const callbackMap = new Map();

const crawler = new PlaywrightCrawler({
    keepAlive: true,
    requestHandler: async ({ request, page }) => {
        console.log(`Scraping ${request.url}`);
        await page.waitForTimeout(3000);
        const screenshot = await page.screenshot();
        const prompt = "The image is a screenshot of a product webpage. " +
            "What is the price of the product? " +
            "Is it on sale? " +
            "What (if any) is the reported price before the sale? " +
            "If no price is visible, describe the page in the error field.";
        const image = {
            inlineData: {
                data: screenshot.toString("base64"),
                mimeType: "image/png",
            },
        };
        const result = (await model.generateContent([prompt, image])).response.text();
        console.log(`Yielding for ${request.url} the response ${result}`);
        callbackMap.get(request.uniqueKey)?.resolve(result);
    },
});

function getCrawlerResponse(url: URL): Promise<{ error: string, result: { price: number, is_sale: boolean, pre_sale_price: number | null } }> {
    return new Promise(async (resolve, reject) => {
        const uniqueKey = crypto.randomUUID();
        callbackMap.set(uniqueKey, { resolve, reject });
        crawler.addRequests([{ url: url.toString(), uniqueKey }]);
    });
}

/*
 * Server
 */

const port = parseInt(process.env.PORT ?? "3000");

const app = express();

app.get('/', async (req, res) => {
    const requestedUrl = new URL(req.query.url as string);
    const result = await getCrawlerResponse(requestedUrl);
    res.statusCode = 200;
    res.type('json').send(result);
});

const server = app.listen(port, () => {
    console.log(`Server running on port ${port}`);
});

crawler.run();

process.on('SIGINT', function () {
    // Crawlee breaks the express.js SIGINT handler, so we need to close it manually
    console.log('SIGINT signal received: closing server');
    server.close();
    console.log('Server closed');
})
