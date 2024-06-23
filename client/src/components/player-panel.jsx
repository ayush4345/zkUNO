import Player from './player'
import StyledButton from './styled-button'
import { useState } from 'react'


export default function PlayerPanel() {
  const [gameSize, setGameSize] = useState(2);

  const showPK = false

  return (
    <div className='relative'>
      {gameSize == 2 && (
        <>
          <Player1 />
          <Player showPK={showPK} name='Player 2' point={100} avatar={3} style={{ left: 80, top: 120 }} />
        </>
      )}
      {gameSize == 3 && (
        <>
          <Player1 />
          <Player showPK={showPK} name='Player 2' point={100} avatar={3} style={{ left: 80, top: 120 }} />
          <Player showPK={showPK} name='Player 3' point={100} style={{ right: 300, top: 120 }} rightSide />
        </>
      )}
      {gameSize == 4 && (
        <>
          <Player1 />
          <Player showPK={showPK} name='Player 2' point={100} avatar={3} style={{ left: 80, top: 120 }} />
          <Player showPK={showPK} name='Player 3' point={100} style={{ right: 300, top: 120 }} rightSide />
          <Player showPK={showPK} name='Player 4' point={100} avatar={5} style={{ left: 80, top: 300 }} />
        </>
      )}
      {gameSize == 4 && (
        <>
          <Player1 />
          <Player showPK={showPK} name='Player 2' point={100} avatar={3} style={{ left: 80, top: 120 }} />
          <Player showPK={showPK} name='Player 3' point={100} style={{ right: 300, top: 120 }} rightSide />
          <Player showPK={showPK} name='Player 4' point={100} avatar={5} style={{ left: 80, top: 300 }} />
          <Player showPK={showPK} name='Player 5' point={100} avatar={7} style={{ right: 300, top: 300 }} rightSide />
        </>
      )}
    </div>

  )
}

function Player1() {

  const x = 360, y = 470
  return (
    <Player
      x={x} y={y}
      style={{ left: x, top: y }}
      isCurrentPlayer={true}
    >
      {
        true && <div className='relative px-6 py-1 text-center'>
          <StyledButton className='bg-[rgb(1,145,186)]' roundedStyle='rounded-full'
          >CHECK</StyledButton>
        </div>
      }
    </Player>
  )
}