<?php
namespace App\Http\Controllers;

use Illuminate\Http\Request;
use Illuminate\Support\Facades\Storage;

class ImageUploadController extends Controller
{
    public function store(Request $request)
    {
        $data = $request->validate([
            'image' => 'required|image|max:5120', // 最大5MB
        ]);

        $path = $data['image']->store('uploads', 'public'); // storage/app/public/uploads/

        return response()->json([
            'url' => url("storage/{$path}") // http://localhost:8000/storage/uploads/xxxx.jpg
        ]);
    }
}
