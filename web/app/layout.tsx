import type { Metadata } from 'next';
import './globals.css';

export const metadata: Metadata = {
  title: 'Flex Force X Trial Admin',
  description: 'Trial operations dashboard for Flex Force X',
};

export default function RootLayout({ children }: { children: React.ReactNode }) {
  return (
    <html lang="en">
      <body>{children}</body>
    </html>
  );
}
