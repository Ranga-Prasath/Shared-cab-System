import { Inter } from 'next/font/google';
import './globals.css';
import { Navbar } from '../components/layout/navbar';

const inter = Inter({ subsets: ['latin'] });

export const metadata = {
  title: 'Shared Cab Platform',
  description: 'Realtime route-sharing cab system demo'
};

export default function RootLayout({ children }: { children: React.ReactNode }) {
  return (
    <html lang="en" className="dark">
      <body className={`${inter.className} bg-black text-white antialiased min-h-screen flex flex-col`}>
        <Navbar />
        <main className="flex-1 w-full bg-black">{children}</main>
      </body>
    </html>
  );
}
