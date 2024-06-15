import Navbar from "@/components/homePage/Navbar"
import Hero from "@/components/homePage/Hero"

export default function Home() {

  return (
    <main className="flex min-h-screen flex-col items-center justify-between">
      <div className="w-full overflow-hidden">
        <Navbar />
        <Hero />
      </div>
    </main>
  )
}
