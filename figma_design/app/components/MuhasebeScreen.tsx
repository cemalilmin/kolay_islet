import { ChevronDown, Plus, Receipt } from 'lucide-react';
import { useState } from 'react';

interface MuhasebeScreenProps {
  onAddCategory: () => void;
}

export default function MuhasebeScreen({ onAddCategory }: MuhasebeScreenProps) {
  const [timeFilter, setTimeFilter] = useState('Bu Ay');
  const [showDropdown, setShowDropdown] = useState(false);

  const timeOptions = ['Bugün', 'Bu Hafta', 'Bu Ay', 'Bu Yıl', 'Tüm Zamanlar'];

  const transactions = [
    { name: 'kumaş alındı - Gider', date: '13 Ocak', amount: '-20000 TL', color: 'bg-gradient-to-br from-orange-400 to-orange-500', icon: '📦' },
    { name: 'dubai model (Kalan Öde...)', date: '13 Ocak', amount: '+1400 TL', color: 'bg-gradient-to-br from-purple-500 to-purple-600', icon: '👗' },
    { name: 'dubai model - Kiralama', date: '13 Ocak', amount: '+600 TL', color: 'bg-gradient-to-br from-purple-500 to-purple-600', icon: '👗' },
    { name: 'dubai model - Satış', date: '', amount: '+5500 TL', color: 'bg-gradient-to-br from-cyan-400 to-cyan-500', icon: '👗' },
  ];

  return (
    <div className="min-h-screen bg-gradient-to-b from-gray-50 to-gray-100">
      {/* Header */}
      <div className="bg-gradient-to-br from-red-600 via-red-600 to-red-700 pt-3 pb-10 px-6 rounded-b-[2.5rem] shadow-2xl shadow-red-900/20">
        <div className="flex items-center justify-between mb-8">
          <div className="text-white/90">
            <div className="text-sm font-medium">15:24</div>
          </div>
          <div className="flex items-center gap-3 text-white/90">
            <div className="text-sm">••••</div>
            <div className="text-sm">📶</div>
            <div className="text-sm">🔋</div>
          </div>
        </div>

        <div className="flex items-center justify-between mb-6">
          <h1 className="text-white text-3xl font-semibold tracking-tight">Muhasebe</h1>
          <div className="relative">
            <button
              onClick={() => setShowDropdown(!showDropdown)}
              className="bg-white/15 backdrop-blur-md border border-white/20 text-white px-4 py-2.5 rounded-2xl flex items-center gap-2 hover:bg-white/25 transition-all duration-200 shadow-lg shadow-black/10"
            >
              <span className="text-sm font-medium">{timeFilter}</span>
              <ChevronDown className="size-4" />
            </button>

            {showDropdown && (
              <div className="absolute right-0 mt-3 bg-white/95 backdrop-blur-xl rounded-3xl shadow-2xl shadow-black/20 py-2 min-w-[180px] z-50 border border-gray-100">
                {timeOptions.map((option) => (
                  <button
                    key={option}
                    onClick={() => {
                      setTimeFilter(option);
                      setShowDropdown(false);
                    }}
                    className={`w-full text-left px-5 py-3.5 hover:bg-gray-50/80 transition-all duration-150 ${
                      option === timeFilter
                        ? 'text-red-600 bg-red-50/50 font-semibold'
                        : 'text-gray-700'
                    }`}
                  >
                    <div className="flex items-center gap-3">
                      <div
                        className={`size-5 rounded-full border-2 flex items-center justify-center transition-all duration-200 ${
                          option === timeFilter
                            ? 'border-red-600 bg-red-50'
                            : 'border-gray-300'
                        }`}
                      >
                        {option === timeFilter && (
                          <div className="size-2.5 rounded-full bg-red-600 shadow-sm"></div>
                        )}
                      </div>
                      {option}
                    </div>
                  </button>
                ))}
              </div>
            )}
          </div>
        </div>

        {/* Gider Ekle Button */}
        <button
          onClick={onAddCategory}
          className="bg-gradient-to-r from-orange-500 via-orange-500 to-orange-600 text-white px-6 py-4 rounded-2xl flex items-center gap-3 w-full shadow-xl shadow-orange-900/25 hover:shadow-2xl hover:shadow-orange-900/30 hover:scale-[1.01] active:scale-[0.99] transition-all duration-200"
        >
          <div className="bg-white/20 backdrop-blur-sm p-2.5 rounded-xl border border-white/30 shadow-inner">
            <Plus className="size-6" strokeWidth={2.5} />
          </div>
          <div className="text-left">
            <div className="font-semibold text-lg">Gider Ekle</div>
            <div className="text-sm text-orange-50/90">Fatura, kira, malzeme</div>
          </div>
        </button>
      </div>

      {/* Bu Ay Card */}
      <div className="mx-6 -mt-6 bg-white/80 backdrop-blur-sm rounded-3xl shadow-xl shadow-black/10 p-6 mb-6 border border-gray-100/50">
        <h2 className="bg-gradient-to-r from-red-600 to-red-700 text-white text-center py-3.5 rounded-2xl font-semibold mb-6 shadow-lg shadow-red-900/20">
          BU AY
        </h2>

        <div className="flex items-center justify-between gap-6">
          {/* Donut Chart - Clean Premium Design */}
          <div className="relative flex items-center justify-center">
            {/* Subtle outer glow */}
            <div className="absolute inset-0 bg-gradient-to-br from-purple-100/30 via-cyan-100/20 to-gray-100/30 rounded-full blur-xl"></div>
            
            <div className="relative size-44">
              <svg className="transform -rotate-90" viewBox="0 0 120 120">
                <defs>
                  {/* Smooth gradients */}
                  <linearGradient id="purpleGradient" x1="0%" y1="0%" x2="100%" y2="100%">
                    <stop offset="0%" stopColor="#A855F7" />
                    <stop offset="100%" stopColor="#9333EA" />
                  </linearGradient>
                  
                  <linearGradient id="cyanGradient" x1="0%" y1="0%" x2="100%" y2="100%">
                    <stop offset="0%" stopColor="#22D3EE" />
                    <stop offset="100%" stopColor="#06B6D4" />
                  </linearGradient>

                  <linearGradient id="grayGradient" x1="0%" y1="0%" x2="100%" y2="100%">
                    <stop offset="0%" stopColor="#9CA3AF" />
                    <stop offset="100%" stopColor="#6B7280" />
                  </linearGradient>

                  {/* Subtle shadow */}
                  <filter id="softShadow" x="-50%" y="-50%" width="200%" height="200%">
                    <feDropShadow dx="0" dy="2" stdDeviation="3" floodOpacity="0.2"/>
                  </filter>
                </defs>
                
                {/* Simple background track */}
                <circle
                  cx="60"
                  cy="60"
                  r="45"
                  fill="none"
                  stroke="#F3F4F6"
                  strokeWidth="16"
                />
                
                {/* Kiralama segment - Purple (30%) */}
                <circle
                  cx="60"
                  cy="60"
                  r="45"
                  fill="none"
                  stroke="url(#purpleGradient)"
                  strokeWidth="16"
                  strokeDasharray="84.82 282.74"
                  strokeDashoffset="0"
                  strokeLinecap="round"
                  filter="url(#softShadow)"
                  className="transition-all duration-500"
                />
                
                {/* Satış segment - Cyan (25%) */}
                <circle
                  cx="60"
                  cy="60"
                  r="45"
                  fill="none"
                  stroke="url(#cyanGradient)"
                  strokeWidth="16"
                  strokeDasharray="70.69 282.74"
                  strokeDashoffset="-84.82"
                  strokeLinecap="round"
                  filter="url(#softShadow)"
                  className="transition-all duration-500"
                />

                {/* Gider segment - Gray (45%) */}
                <circle
                  cx="60"
                  cy="60"
                  r="45"
                  fill="none"
                  stroke="url(#grayGradient)"
                  strokeWidth="16"
                  strokeDasharray="127.23 282.74"
                  strokeDashoffset="-155.51"
                  strokeLinecap="round"
                  filter="url(#softShadow)"
                  className="transition-all duration-500"
                />
              </svg>
              
              {/* Center content - Red for loss */}
              <div className="absolute inset-0 flex flex-col items-center justify-center">
                <div className="bg-gradient-to-br from-red-500 to-red-600 text-white font-bold text-base px-3.5 py-1.5 rounded-full shadow-lg">
                  ₺-9900
                </div>
                <div className="text-[10px] text-gray-500 font-bold tracking-wider uppercase mt-1">Net Zarar</div>
              </div>

              {/* Clean percentage labels */}
              <div className="absolute top-1 right-2">
                <div className="bg-purple-500 text-white text-[10px] font-bold px-2 py-1 rounded-lg shadow-lg">
                  30%
                </div>
              </div>
              <div className="absolute bottom-5 right-2">
                <div className="bg-cyan-500 text-white text-[10px] font-bold px-2 py-1 rounded-lg shadow-lg">
                  25%
                </div>
              </div>
              <div className="absolute bottom-1 left-2">
                <div className="bg-gray-500 text-white text-[10px] font-bold px-2 py-1 rounded-lg shadow-lg">
                  45%
                </div>
              </div>
            </div>
          </div>

          {/* Legend - Enhanced */}
          <div className="flex-1 space-y-3.5">
            <div className="bg-gradient-to-r from-purple-50 to-purple-100/50 rounded-xl p-3 border border-purple-200/50 shadow-sm">
              <div className="flex items-center justify-between mb-1">
                <div className="flex items-center gap-2">
                  <div className="size-3.5 rounded-full bg-gradient-to-br from-purple-400 to-purple-600 shadow-md"></div>
                  <span className="text-sm text-gray-800 font-semibold">Kiralama</span>
                </div>
                <span className="text-xs text-purple-600 font-bold bg-purple-100 px-2 py-0.5 rounded-full">30%</span>
              </div>
              <span className="font-bold text-green-600 text-base ml-5">+₺4600</span>
            </div>

            <div className="bg-gradient-to-r from-cyan-50 to-cyan-100/50 rounded-xl p-3 border border-cyan-200/50 shadow-sm">
              <div className="flex items-center justify-between mb-1">
                <div className="flex items-center gap-2">
                  <div className="size-3.5 rounded-full bg-gradient-to-br from-cyan-400 to-cyan-600 shadow-md"></div>
                  <span className="text-sm text-gray-800 font-semibold">Satış</span>
                </div>
                <span className="text-xs text-cyan-600 font-bold bg-cyan-100 px-2 py-0.5 rounded-full">25%</span>
              </div>
              <span className="font-bold text-green-600 text-base ml-5">+₺5500</span>
            </div>

            <div className="bg-gradient-to-r from-gray-50 to-gray-100/50 rounded-xl p-3 border border-gray-200/50 shadow-sm">
              <div className="flex items-center justify-between mb-1">
                <div className="flex items-center gap-2">
                  <div className="size-3.5 rounded-full bg-gradient-to-br from-gray-400 to-gray-500 shadow-md"></div>
                  <span className="text-sm text-gray-800 font-semibold">Gider</span>
                </div>
                <span className="text-xs text-gray-600 font-bold bg-gray-100 px-2 py-0.5 rounded-full">45%</span>
              </div>
              <span className="font-bold text-red-600 text-base ml-5">-₺20000</span>
            </div>
          </div>
        </div>
      </div>

      {/* Son İşlemler */}
      <div className="px-6 mb-6">
        <button className="bg-gradient-to-r from-red-600 to-red-700 text-white px-6 py-3.5 rounded-2xl font-semibold shadow-lg shadow-red-900/20 hover:shadow-xl hover:shadow-red-900/25 hover:scale-[1.01] active:scale-[0.99] transition-all duration-200 flex items-center gap-2">
          <Receipt className="size-5" strokeWidth={2.5} />
          Son İşlemler
        </button>
      </div>

      {/* Transaction List */}
      <div className="px-6 space-y-3 pb-6">
        {transactions.map((transaction, i) => (
          <div
            key={i}
            className="bg-white/90 backdrop-blur-sm rounded-2xl p-4 flex items-center gap-4 shadow-md shadow-black/5 hover:shadow-lg hover:shadow-black/10 hover:scale-[1.01] active:scale-[0.99] transition-all duration-200 border border-gray-100/50"
          >
            <div className={`size-12 rounded-xl ${transaction.color} flex items-center justify-center text-2xl shadow-lg shadow-black/15`}>
              {transaction.icon}
            </div>
            <div className="flex-1">
              <div className="font-semibold text-gray-900">{transaction.name}</div>
              {transaction.date && (
                <div className="text-sm text-gray-500 mt-0.5">
                  {transaction.date} {transaction.date && '& havru ilmaa'}
                </div>
              )}
            </div>
            <div
              className={`font-bold text-lg ${
                transaction.amount.startsWith('+')
                  ? 'text-green-600'
                  : 'text-red-600'
              }`}
            >
              {transaction.amount}
              {transaction.date && (
                <div className="text-xs text-gray-400 font-normal mt-1">Basılı tut: sil</div>
              )}
            </div>
          </div>
        ))}
      </div>
    </div>
  );
}