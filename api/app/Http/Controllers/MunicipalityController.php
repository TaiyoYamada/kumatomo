<?php

namespace App\Http\Controllers;

use Illuminate\Http\JsonResponse;
use App\Enums\City;

class MunicipalityController extends Controller
{
    /**
     * Return list of municipalities (cities) used for tags.
     */
    public function index(): JsonResponse
    {
        return response()->json([
            'prefecture' => '熊本県',
            'cities' => City::names(),
        ]);
    }
}

