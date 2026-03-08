'use client';

import * as React from 'react';
import { useRef, useEffect, useState } from 'react';

interface BottomSheetProps {
    isOpen: boolean;
    onClose?: () => void;
    title?: string;
    children: React.ReactNode;
    snapPoints?: string[]; // e.g. ['20%', '50%', '90%']
    initialSnap?: number;
}

export function BottomSheet({
    isOpen,
    onClose,
    title,
    children,
    snapPoints = ['50%', '90%'],
    initialSnap = 0
}: BottomSheetProps) {
    const [currentSnap, setCurrentSnap] = useState(initialSnap);
    const sheetRef = useRef<HTMLDivElement>(null);
    const [isDragging, setIsDragging] = useState(false);
    const [startY, setStartY] = useState(0);
    const [currentY, setCurrentY] = useState(0);

    useEffect(() => {
        if (isOpen) {
            document.body.style.overflow = 'hidden';
        } else {
            document.body.style.overflow = '';
            setCurrentSnap(initialSnap); // Reset on close
        }
        return () => {
            document.body.style.overflow = '';
        };
    }, [isOpen, initialSnap]);

    if (!isOpen) return null;

    const handlePointerDown = (e: React.PointerEvent) => {
        setIsDragging(true);
        setStartY(e.clientY);
        if (sheetRef.current) {
            sheetRef.current.setPointerCapture(e.pointerId);
        }
    };

    const handlePointerMove = (e: React.PointerEvent) => {
        if (!isDragging) return;
        const deltaY = e.clientY - startY;
        if (deltaY > 0) {
            setCurrentY(deltaY);
        }
    };

    const handlePointerUp = (e: React.PointerEvent) => {
        if (!isDragging) return;
        setIsDragging(false);

        if (sheetRef.current) {
            sheetRef.current.releasePointerCapture(e.pointerId);
        }

        // Simple snap logic based on drag distance
        if (currentY > 100) {
            if (currentSnap > 0) {
                setCurrentSnap(currentSnap - 1);
            } else if (onClose) {
                onClose();
            }
        } else if (currentY < -50 && currentSnap < snapPoints.length - 1) {
            setCurrentSnap(currentSnap + 1);
        }

        setCurrentY(0);
    };

    const activeHeight = snapPoints[currentSnap] || '50%';

    return (
        <>
            <div
                className="fixed inset-0 z-40 bg-black/60 backdrop-blur-sm transition-opacity"
                onClick={onClose}
                aria-hidden="true"
            />
            <div
                ref={sheetRef}
                onPointerDown={handlePointerDown}
                onPointerMove={handlePointerMove}
                onPointerUp={handlePointerUp}
                onPointerCancel={handlePointerUp}
                className="fixed inset-x-0 bottom-0 z-50 flex w-full flex-col rounded-t-[28px] bg-[#0a0a0a] border-t border-white/5 shadow-[0_-20px_40px_-10px_rgba(0,0,0,0.8)] transition-all duration-300 ease-out will-change-transform"
                style={{
                    height: activeHeight,
                    transform: `translateY(${currentY}px)`,
                    touchAction: 'none'
                }}
            >
                <div className="flex w-full items-center justify-center p-4 cursor-grab active:cursor-grabbing">
                    <div className="h-1.5 w-12 rounded-full bg-neutral-700/80" />
                </div>

                {title && (
                    <div className="px-6 pb-2">
                        <h2 className="text-2xl font-bold tracking-tight text-white">{title}</h2>
                    </div>
                )}

                <div className="flex-1 overflow-y-auto px-6 pb-8 custom-scrollbar text-neutral-300">
                    {children}
                </div>
            </div>
        </>
    );
}
