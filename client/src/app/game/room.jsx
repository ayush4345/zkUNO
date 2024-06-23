'use client'
import PlayerPanel from '@/components/player-panel'
import { useState } from 'react'

export default function GameRoom() {

  const [loading, setLoading] = useState(true);

  return (
    <>
      <div className='hidden scale-[0.975]'></div>
      <div className='transition-transform relative w-full max-w-[1280px] h-[720px] m-20 mt-10 mx-auto bg-[url("/bg-3.jpg")] select-none rounded-3xl overflow-hidden shadow-[0_0_20px_rgba(0,0,0,0.8)]'
        onTransitionEnd={e => {
          e.target.classList.remove('scale-[0.975]')
        }}
      >
        <PlayerPanel></PlayerPanel>
      </div>
    </>
  )
}