import express, {Request, Response} from 'express';
import {PrismaClient} from '@prisma/client';
import bodyParser from 'body-parser';
import cors from 'cors'
import {Stripe} from "stripe";

const app = express();
const prisma = new PrismaClient();
const stripe = new Stripe('sk_test_7mJuPfZsBzc3JkrANrFrcDqC');

const corsOptions: cors.CorsOptions = {
    origin: 'http://localhost:5173',
    credentials: true,
    methods: ['GET', 'POST', 'PATCH', 'DELETE'],
    allowedHeaders: ['Content-Type', 'Authorization', 'cache-control'],
    maxAge: 60 * 60 * 24 * 30,
    preflightContinue: false,
}
// Middleware
app.use(bodyParser.json());
app.use(cors(corsOptions))

// CRUD endpoints for Categories
app.post('/create-payment-intent', async (req, res) => {
    const {amount, currency} = req.body
    try {
        const paymentIntent = await stripe.paymentIntents.create({
            amount,
            currency,
        });

        res.status(200).json({client_secret: paymentIntent.client_secret});
    } catch (error) {
        console.error('Error creating payment intent:', error);
        res.status(500).json({error: error});
    }
});

// Create a new Category
app.post('/categories', async (req: Request, res: Response) => {
    const {name} = req.body;
    const category = await prisma.category.create({
        data: {name},
    });
    res.json(category);
});

// Read all Categories
app.get('/categories', async (req: Request, res: Response) => {
    const categories = await prisma.category.findMany();
    res.json(categories);
});

// Read a Category by ID
app.get('/categories/:id', async (req: Request, res: Response) => {
    const {id} = req.params;
    const category = await prisma.category.findUnique({
        where: {id: Number(id)},
    });
    res.json(category);
});

// Update a Category by ID
app.put('/categories/:id', async (req: Request, res: Response) => {
    const {id} = req.params;
    const {name} = req.body;
    const category = await prisma.category.update({
        where: {id: Number(id)},
        data: {name},
    });
    res.json(category);
});

// Delete a Category by ID
app.delete('/categories/:id', async (req: Request, res: Response) => {
    const {id} = req.params;
    await prisma.category.delete({
        where: {id: Number(id)},
    });
    res.json({message: 'Category deleted'});
});

// CRUD endpoints for Products

// Create a new Product
app.post('/products', async (req: Request, res: Response) => {
    const {name, categoryId} = req.body;
    const product = await prisma.product.create({
        data: {name, categoryId},
    });
    res.json(product);
});

// Read all Products
app.get('/products', async (req: Request, res: Response) => {
    const products = await prisma.product.findMany({
        include: {category: true},
    });
    res.json(products);
});

// Read a Product by ID
app.get('/products/:id', async (req: Request, res: Response) => {
    const {id} = req.params;
    const product = await prisma.product.findUnique({
        where: {id: Number(id)},
        include: {category: true},
    });
    res.json(product);
});

// Update a Product by ID
app.put('/products/:id', async (req: Request, res: Response) => {
    const {id} = req.params;
    const {name, categoryId} = req.body;
    const product = await prisma.product.update({
        where: {id: Number(id)},
        data: {name, categoryId},
    });
    res.json(product);
});

// Update a Product by ID
app.patch('/products/:id', async (req: Request, res: Response) => {
    const { id } = req.params;
    const { name, categoryId, isAddedToCart } = req.body;

    try {
        const product = await prisma.product.update({
            where: { id: Number(id) },
            data: {
                name: name !== undefined ? name : undefined, // Update only if name is provided
                categoryId: categoryId !== undefined ? categoryId : undefined, // Update only if categoryId is provided
                isAddedToCart: isAddedToCart !== undefined ? isAddedToCart : undefined, // Update to the value of isAddedToCart or undefined if not provided
            },
        });
        res.json(product);
    } catch (error) {
        console.error(error); // Log the error for debugging purposes
        res.status(500).json({ error: 'Failed to update product' });
    }
});

// Delete a Product by ID
app.delete('/products/:id', async (req: Request, res: Response) => {
    const {id} = req.params;
    await prisma.product.delete({
        where: {id: Number(id)},
    });
    res.json({message: 'Product deleted'});
});

// Start the server
const PORT = 3000;
app.listen(PORT, () => {
    console.log(`Server is running on http://localhost:${PORT}`);
});
