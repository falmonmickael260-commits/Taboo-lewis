import "./globals.css";
import type { Metadata } from "next";

export const metadata: Metadata = {
  title: "Taboo Live",
  description: "Jeu Taboo multijoueur en temps réel"
};

export default function RootLayout({ children }: { children: React.ReactNode }) {
  return <html lang="fr"><body>{children}</body></html>;
}
