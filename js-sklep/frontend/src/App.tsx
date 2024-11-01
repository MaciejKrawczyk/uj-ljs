import {Card, CardContent, CardDescription, CardFooter, CardHeader, CardTitle} from "@/components/ui/card.tsx";
import {useEffect, useState} from "react";
import {Carousel, CarouselContent, CarouselItem, CarouselNext, CarouselPrevious} from "@/components/ui/carousel.tsx";
import {Button} from "@/components/ui/button.tsx";
import {Loader2, ShoppingCart} from 'lucide-react'
import {
    Drawer,
    DrawerContent,
    DrawerDescription,
    DrawerFooter,
    DrawerHeader,
    DrawerTitle,
    DrawerTrigger
} from "@/components/ui/drawer.tsx";
import {axiosInstance} from "@/setup";
import {
    Dialog,
    DialogContent,
    DialogDescription,
    DialogHeader,
    DialogTitle,
    DialogTrigger
} from "@/components/ui/dialog.tsx";
import CheckoutForm from "@/CheckoutForm.tsx";

type Product = {
    isAddedToCart: boolean,
    categoryId: number,
    id: number,
    name: string,
    price: number,
    category: { id: number, name: string }
}

export default function App() {
    const [isLoading, setIsLoading] = useState(false);
    const [products, setProducts] = useState<Product[]>([]);

    async function getProducts() {
        try {
            const response = await axiosInstance.get("/products");
            setProducts(response.data);
        } catch (error) {
            console.error(error);
        }
    }

    useEffect(() => {
        getProducts();
    }, []);

    async function addToCart(productId: number) {
        setIsLoading(true);
        try {
            await axiosInstance.patch(`/products/${productId}`, {
                isAddedToCart: true
            });
            await getProducts();
        } catch (e) {
            console.error(e);
        } finally {
            setIsLoading(false);
        }
    }

    async function removeFromCart(productId: number) {
        setIsLoading(true);
        try {
            await axiosInstance.patch(`/products/${productId}`, {
                isAddedToCart: false
            });
            setProducts((prevProducts) =>
                prevProducts.map((product) =>
                    product.id === productId ? {...product, isAddedToCart: false} : product
                )
            );
        } catch (e) {
            console.error(e);
        } finally {
            setIsLoading(false);
        }
    }

    function getPriceOfProductsInCart() {
        let totalPrice = 0;
        products.forEach(product => {
            if (product.isAddedToCart) {
                totalPrice += product.price;
            }
        });
        return totalPrice;
    }

    return (
        <div>
            <Drawer>
                <Card>
                    <CardContent className={'flex justify-between items-center p-4'}>
                        <p className={'text-2xl font-bold italic'}>M.K. Shop</p>
                        <DrawerTrigger asChild>
                            <Button variant={'ghost'}>
                                <ShoppingCart className={'h-4 w-4'}/>
                            </Button>
                        </DrawerTrigger>
                    </CardContent>
                </Card>

                <Card className={'w-full my-5'}>
                    <CardHeader>
                        <CardTitle>Produkty</CardTitle>
                        <CardDescription>Przewijaj aby przeglądać produkty</CardDescription>
                    </CardHeader>
                    <CardContent className={'w-full flex justify-center my-3'}>
                        <Carousel className="w-full">
                            <CarouselContent>
                                {products.map((product, index) => (
                                    <CarouselItem key={index}>
                                        <div className="p-1">
                                            <Card>
                                                <CardContent className="flex items-center justify-center p-6">
                                                    <div className="flex flex-col">
                                                            <span
                                                                className="text-4xl font-semibold">{product.name}</span>
                                                        <span
                                                            className="text-sm font-light">{product.category.name}</span>
                                                    </div>
                                                </CardContent>
                                                <CardFooter>
                                                    <Button
                                                        onClick={async () => await addToCart(product.id)}
                                                        disabled={isLoading}
                                                    >
                                                        {isLoading && <Loader2
                                                            className="mr-2 h-4 w-4 animate-spin"
                                                        />}
                                                        Dodaj do koszyka
                                                    </Button>
                                                </CardFooter>
                                            </Card>
                                        </div>
                                    </CarouselItem>
                                ))}
                            </CarouselContent>
                            <CarouselPrevious/>
                            <CarouselNext/>
                        </Carousel>
                    </CardContent>
                </Card>

                <footer>
                    <Card>
                        <CardContent className={'flex justify-center items-center p-4'}>
                            <p className={'text-gray-400'}>Copyright © 2023 M.K. Shop</p>
                        </CardContent>
                    </Card>
                </footer>

                <DrawerContent>
                    <DrawerHeader>
                        <DrawerTitle>Koszyk</DrawerTitle>
                        <DrawerDescription>Masz niesamowite produkty w koszyku!!</DrawerDescription>
                    </DrawerHeader>
                    <div className={'h-96'}>
                        {products.map((product) => {
                            if (product.isAddedToCart) {
                                return (
                                    <Card key={product.id} className={'flex items-center justify-between p-6'}>
                                        <span className="text-xl">{product.name}</span>
                                        <div className={'flex gap-2 items-center'}>
                                            <span className="text-sm">Cena: {product.price} zł</span>
                                            <Button
                                                onClick={async () => await removeFromCart(product.id)}
                                                disabled={isLoading}
                                            >
                                                {isLoading && <Loader2
                                                    className="mr-2 h-4 w-4 animate-spin"
                                                />}
                                                Usuń z koszyka
                                            </Button>
                                        </div>
                                    </Card>
                                )
                            }
                        })}
                    </div>
                    <DrawerFooter>
                        <Dialog>
                            <DialogTrigger asChild>
                                <Button>Kup</Button>
                            </DialogTrigger>
                            <DialogContent className="sm:max-w-md">
                                <DialogHeader>
                                    <DialogTitle>Finalizacja zakupu</DialogTitle>
                                    <DialogDescription>
                                        Wypełnij formularz aby zakończyć zakup. Kwota: {getPriceOfProductsInCart()}
                                    </DialogDescription>
                                </DialogHeader>
                                <CheckoutForm amount={getPriceOfProductsInCart()}/>
                            </DialogContent>
                        </Dialog>
                    </DrawerFooter>
                </DrawerContent>
            </Drawer>
        </div>
    )
}
