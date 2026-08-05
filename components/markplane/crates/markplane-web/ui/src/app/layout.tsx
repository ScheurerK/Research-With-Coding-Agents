import type { Metadata } from "next";
import { GeistSans } from "geist/font/sans";
import { GeistMono } from "geist/font/mono";
import "./globals.css";
import { Providers } from "@/components/providers";
import { AppSidebar } from "@/components/layout/app-sidebar";
import { CommandPaletteWrapper } from "@/components/layout/command-palette-wrapper";
import { GlobalCreateDialog } from "@/components/layout/global-create-dialog";
import { ErrorBoundary } from "@/components/domain/error-boundary";
import { MobileHeader } from "@/components/layout/mobile-header";
import { SidebarInset, SidebarProvider } from "@/components/ui/sidebar";
import { Toaster } from "@/components/ui/sonner";


export const metadata: Metadata = {
  title: "Markplane",
  description: "AI-native project management",
};

export default function RootLayout({
  children,
}: Readonly<{
  children: React.ReactNode;
}>) {
  return (
    <html lang="en" suppressHydrationWarning>
      <body
        className={`${GeistSans.variable} ${GeistMono.variable} font-sans antialiased`}
      >
        <Providers>
          <SidebarProvider>
            <AppSidebar />
            <SidebarInset>
              <MobileHeader />
              <main className="flex-1">
                <ErrorBoundary>{children}</ErrorBoundary>
              </main>
            </SidebarInset>
            <CommandPaletteWrapper />
            <GlobalCreateDialog />
          </SidebarProvider>
          <Toaster position="bottom-right" />
        </Providers>
      </body>
    </html>
  );
}
