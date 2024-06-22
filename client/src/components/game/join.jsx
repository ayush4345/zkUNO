'use client'

import StyledButton from '@/components/styled-button'
import { useRef, useEffect, useState } from 'react'
import Link from 'next/link';
import {
    Dialog,
    DialogContent,
    DialogTrigger,
} from "@/components/ui/dialog"
import { checkAddress, getUserData } from '@/util/databaseFunctions';
import { useRouter } from 'next/navigation';
import { useDynamicContext } from '@dynamic-labs/sdk-react-core';
import { DynamicWidget } from '@dynamic-labs/sdk-react-core';

export default function JoinGame() {

    const [walletConnected, setWalletConnected] = useState(false);
    const [gameId, setGameId] = useState("")
    const [accounts, setAccounts] = useState(null);
    const [profile, setProfile] = useState(false);
    const [open, setOpen] = useState(false);
    const [loading, setLoading] = useState(false)
    const [joining, setJoining] = useState(false)

    const router = useRouter()

    const { user } = useDynamicContext();

    const joinGame = () => {
        if (userData) {
            setJoining(true)

            setTimeout(() => {
                router.push(`/game?gameId=${gameId}`);
            }, 1500);

            setJoining(false)
        }
    }

    const checkUserData = async () => {
        try {
            let data = { id: "", address: "", name: "", userName: "", status: "" };

            if (userData == data) {
                setOpen(true)
            }
            if (user?.verifiedCredentials[0].address) {
                setWalletConnected(true)
                setLoading(true)
                checkAddress(user.verifiedCredentials[0].address).then((res) => {
                    console.log("res:", res);
                    setLoading(false)
                    if (res) {
                        setProfile(true)
                    }
                })
                data = await getUserData(user.verifiedCredentials[0].address)
            }

            console.log("data", data.response[0])

        } catch (error) {
            console.log(error.message, error.code)
        }
    }

    const openHandler = () => {
        setOpen(false)
    }

    return (
        <div className='bg-white w-[1280px] h-[720px] overflow-hidden mx-auto my-8 px-4 py-2 rounded-lg bg-cover bg-[url("/bg-2.jpg")] relative shadow-[0_0_20px_rgba(0,0,0,0.8)]'>
            {/* <div className='absolute top-5 left-5 w-40 h-40 bg-no-repeat bg-[url("/logo.png")]'></div> */}


            <div className='absolute inset-0 bg-no-repeat bg-[url("/table-1.png")]'></div>

            <div className='absolute left-8 -right-8 top-14 -bottom-14 bg-no-repeat bg-[url("/dealer.png")] transform-gpu'>
                <div className='absolute -left-8 right-8 -top-14 bottom-14 bg-no-repeat bg-[url("/card-0.png")] animate-pulse'></div>
            </div>
            <div className='absolute top-0 left-1/2 right-0 bottom-0 pr-20 py-12'>
                <div className='relative text-center flex justify-center'>
                    <img src='/login-button-bg.png' />
                    <div className='left-1/2 -translate-x-1/2 absolute bottom-4'>
                        <DynamicWidget innerButtonComponent={
                            <StyledButton data-testid="connect" roundedStyle='rounded-full' className='bg-[#ff9000] text-2xl'>{accounts ? `Connected Wallet` : `Connect Wallet`}</StyledButton>
                        } />
                    </div>

                </div>
                {user?.verifiedCredentials[0].address &&
                    <div className='flex flex-col items-center'>
                        <input onChange={(e) => setGameId(e.target.value)} className='w-full border-2 mt-3 border-[#00b69a] bg-gray-600/60 rounded-md p-5 py-2 text-white' placeholder='enter the code' />
                        <StyledButton className='w-full bg-[#00b69a] bottom-4 text-2xl mt-3' onClick={() => joinGame()} disabled={!(gameId != "")}>{joining ? `Joining Game...` : `Enter Game`} </StyledButton>
                    </div>
                }
            </div>
        </div>
    )
}