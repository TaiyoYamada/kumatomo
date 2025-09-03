#  ひだまり
## アプリの概要

- 熊本県掲示板アプリ
まだ知られていない、温かくて魅力的なお店を発見し、その魅力を広めるためのコミュニティアプリです。
ユーザーは、アプリを使って「ひだまり」のような素敵なスポットを見つけ、その魅力を写真や文章で投稿することができます。


## 主な機能

- **投稿機能**: お店の写真や感想を、簡単に投稿できます。
- **発見機能**: マップやカテゴリから、新しいお店を探すことができます。
- **クーポン機能**: 投稿することで、お店で使えるクーポンを獲得できます。


## docs

### 要件定義書

```
https://docs.google.com/document/d/1oieeV_WKE8YKsUwU8Ret50e5lnSVQDKWlBRMlKIioBg/edit?tab=t.0
```

### DB設計書
```
https://docs.google.com/spreadsheets/d/1mYCOM8me72SK_WAiY8aZAGK7daOr7pVdh0_Mcgv9Zto/edit?gid=1467023154#gid=1467023154
```


## Laravel APIの起動手順（ローカル専用）

```bash
docker compose build
docker compose up -d
```
```
cd Hidamari_admin
yarn dev
```


## TODO（自分メモ）

* [ ] Storageサービスの最終決定（Cloudinary or ImgBB）
* [ ] 本番環境（Render）にデプロイ予定

- httpsにしたい

---

## ライセンス

MITライセンス（個人用）
