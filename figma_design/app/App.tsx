import MuhasebeScreen from '@/app/components/MuhasebeScreen';

export default function App() {
  return (
    <div className="size-full flex items-center justify-center bg-gray-100">
      <div className="w-full max-w-md h-full">
        <MuhasebeScreen onAddCategory={() => console.log('Add category')} />
      </div>
    </div>
  );
}