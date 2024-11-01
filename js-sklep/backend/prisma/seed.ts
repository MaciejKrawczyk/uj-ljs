import { PrismaClient } from '@prisma/client'

const prisma = new PrismaClient()

async function main() {
    // Seed Categories
    const electronicsCategory = await prisma.category.upsert({
        where: { id: 1 },
        update: {},
        create: {
            name: 'Electronics',
        },
    })

    const furnitureCategory = await prisma.category.upsert({
        where: { id: 2 },
        update: {},
        create: {
            name: 'Furniture',
        },
    })

    const clothingCategory = await prisma.category.upsert({
        where: { id: 3 },
        update: {},
        create: {
            name: 'Clothing',
        },
    })

    const groceriesCategory = await prisma.category.upsert({
        where: { id: 4 },
        update: {},
        create: {
            name: 'Groceries',
        },
    })

    // Seed Products
    const phoneProduct = await prisma.product.upsert({
        where: { id: 1 },
        update: {},
        create: {
            name: 'Smartphone',
            categoryId: electronicsCategory.id,
        },
    })

    const laptopProduct = await prisma.product.upsert({
        where: { id: 2 },
        update: {},
        create: {
            name: 'Laptop',
            categoryId: electronicsCategory.id,
        },
    })

    const sofaProduct = await prisma.product.upsert({
        where: { id: 3 },
        update: {},
        create: {
            name: 'Sofa',
            categoryId: furnitureCategory.id,
        },
    })

    const diningTableProduct = await prisma.product.upsert({
        where: { id: 4 },
        update: {},
        create: {
            name: 'Dining Table',
            categoryId: furnitureCategory.id,
        },
    })

    const tshirtProduct = await prisma.product.upsert({
        where: { id: 5 },
        update: {},
        create: {
            name: 'T-shirt',
            categoryId: clothingCategory.id,
        },
    })

    const jeansProduct = await prisma.product.upsert({
        where: { id: 6 },
        update: {},
        create: {
            name: 'Jeans',
            categoryId: clothingCategory.id,
        },
    })

    const appleProduct = await prisma.product.upsert({
        where: { id: 7 },
        update: {},
        create: {
            name: 'Apple',
            categoryId: groceriesCategory.id,
        },
    })

    const milkProduct = await prisma.product.upsert({
        where: { id: 8 },
        update: {},
        create: {
            name: 'Milk',
            categoryId: groceriesCategory.id,
        },
    })

    console.log({
        electronicsCategory,
        furnitureCategory,
        clothingCategory,
        groceriesCategory,
        phoneProduct,
        laptopProduct,
        sofaProduct,
        diningTableProduct,
        tshirtProduct,
        jeansProduct,
        appleProduct,
        milkProduct,
    })
}

main()
.then(async () => {
    await prisma.$disconnect()
})
.catch(async (e) => {
    console.error(e)
    await prisma.$disconnect()
    process.exit(1)
})
