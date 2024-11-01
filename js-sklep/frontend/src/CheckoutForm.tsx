import {useEffect, useState} from 'react';
import {Elements, PaymentElement} from '@stripe/react-stripe-js';
import {loadStripe} from '@stripe/stripe-js';
import {Button} from "@/components/ui/button.tsx";
import {axiosInstance} from "@/setup.ts";

const stripePromise = loadStripe('pk_test_51AROWSJX9HHJ5bycpEUP9dK39tXufyuWogSUdeweyZEXy3LC7M8yc5d9NlQ96fRCVL0BlAu7Nqt4V7N5xZjJnrkp005fDiTMIr');

const CheckoutForm = ({amount}) => {
    const [clientSecret, setClientSecret] = useState(null);

    useEffect(() => {
        const getClientSecret = async () => {
            const response = await axiosInstance.post('/create-payment-intent', {
                amount: amount,
                currency: 'pln'
            });
            const {client_secret} = await response.data;
            setClientSecret(client_secret);
        };

        if (amount) {
            getClientSecret();
        }
    }, [amount]);

    const options = {
        clientSecret: clientSecret
    };

    return (
        clientSecret && (
            <Elements stripe={stripePromise} options={options}>
                <form className={'flex gap-3 flex-col'}>
                    <PaymentElement/>
                    <Button>Kup</Button>
                </form>
            </Elements>
        )
    );
};

export default CheckoutForm;
