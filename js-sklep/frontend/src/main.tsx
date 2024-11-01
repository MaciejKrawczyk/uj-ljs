import {StrictMode} from 'react'
import {createRoot} from 'react-dom/client'
import './index.css'
import App from './App.tsx'


createRoot(document.getElementById('root')!).render(
    <StrictMode>
        <div className="flex justify-center min-h-screen bg-gray-100">
            <div className="fixed md:w-9/12 w-full bg-white p-8 rounded-lg shadow-lg text-center">
                <App/>
            </div>
        </div>
    </StrictMode>
)
