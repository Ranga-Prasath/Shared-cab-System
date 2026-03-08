'use client';

export function Button({
  children,
  onClick,
  type = 'button',
  className = '',
  disabled = false
}: {
  children: React.ReactNode;
  onClick?: () => void;
  type?: 'button' | 'submit';
  className?: string;
  disabled?: boolean;
}) {
  return (
    <button
      type={type}
      onClick={onClick}
      disabled={disabled}
      className={`rounded-xl bg-white px-5 py-3.5 font-semibold text-black transition-all duration-200 hover:bg-gray-100 active:scale-[0.98] disabled:opacity-50 disabled:pointer-events-none shadow-sm ${className}`}
    >
      {children}
    </button>
  );
}