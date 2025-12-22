<?php

namespace App\Http\Requests;

use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Validation\ValidationException;

class StoreCommentRequest extends FormRequest
{
    /**
     * Determine if the user is authorized to make this request.
     */
    public function authorize(): bool
    {
        return auth()->check();
    }

    /**
     * Get the validation rules that apply to the request.
     *
     * @return array<string, \Illuminate\Contracts\Validation\ValidationRule|array<mixed>|string>
     */
    public function rules(): array
    {
        return [
            'content' => [
                'nullable',
                'string',
                'max:1000',
            ],
            'image' => [
                'nullable',
                'image',
                'mimes:jpeg,png,jpg,gif,webp',
                'max:5120', // 5MB max
                'dimensions:min_width=100,min_height=100,max_width=4096,max_height=4096'
            ],
            'image_url' => [
                'nullable',
                'url',
                'max:2048',
                'regex:/\.(jpeg|jpg|png|gif|webp)$/i'
            ],
        ];
    }

    /**
     * Get custom validation messages.
     *
     * @return array<string, string>
     */
    public function messages(): array
    {
        return [
            'content.required' => 'コメント内容は必須です。',
            'content.string' => 'コメント内容は文字列である必要があります。',
            'content.max' => 'コメント内容は1000文字以内で入力してください。',
            
            'image.image' => 'アップロードするファイルは画像である必要があります。',
            'image.mimes' => '画像はjpeg、png、jpg、gif、webp形式のみ対応しています。',
            'image.max' => '画像サイズは5MB以下にしてください。',
            'image.dimensions' => '画像サイズは100x100ピクセル以上、4096x4096ピクセル以下にしてください。',
            
            'image_url.url' => '有効な画像URLを入力してください。',
            'image_url.max' => '画像URLは2048文字以内で入力してください。',
            'image_url.regex' => '画像URLは有効な画像形式（jpeg、jpg、png、gif、webp）である必要があります。',
        ];
    }

    /**
     * Configure the validator instance.
     *
     * @param  \Illuminate\Validation\Validator  $validator
     * @return void
     */
    public function withValidator($validator)
    {
        $validator->after(function ($validator) {
            // Ensure either content has meaningful text or an image is provided
            $content = trim($this->input('content', ''));
            $hasImage = $this->hasFile('image') || !empty($this->input('image_url'));
            
            if (empty($content) && !$hasImage) {
                $validator->errors()->add('general', 'コメント内容または画像のいずれかを入力してください。');
            }
        });
    }
}
