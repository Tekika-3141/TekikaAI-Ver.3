# Tekika AI — 開発引き継ぎ

> 対象: `Tekika-3141/TekikaAI-Ver.3`。2026-09-28にローカルのソースとGitHubの`main`向けREADMEを確認。
> この文書は開発者向けのローカル引き継ぎ資料です。README.mdは一般利用者向けです。
> APIキー、トークン、個人データは記載・コミットしないでください。

## 現在の構成

- Windows/Linux/macOS向けのローカルAIエージェント。BackendはFastAPI、FrontendはNext.js。
- Ollamaを含む複数LLM provider（OpenAI、Anthropic Claude、Google Gemini）に対応。
- Quality modeはツール実行を含むエージェントループ、Speed modeはツールを使わない応答。
- 会話履歴はSQLite、長期記憶はChromaDB。Git、ファイルシステム、画像生成、プラグインのツールを持つ。
- Windows向けに `setup-tekika.bat`、`start-tekika.bat`、`environment-checker.bat`、配布ZIP作成用スクリプトがある。
- READMEの記述では、開発引き継ぎはこのローカル専用ファイルに分離されている。

## 主なコード位置

| Path | 役割 |
|---|---|
| `tekika-ai-backend/backend/main.py` | FastAPI endpoints、startup、tool登録、SSE |
| `tekika-ai-backend/backend/config.py` | 環境変数と設定 |
| `tekika-ai-backend/backend/agent/orchestrator.py` | 会話、Quality/Speed、memory、tool loop |
| `tekika-ai-backend/backend/agent/base_client.py` | provider共通契約・canonical tools |
| `tekika-ai-backend/backend/agent/factory.py` | provider生成 |
| `tekika-ai-backend/backend/agent/providers/` | Ollama/OpenAI/Claude/Gemini実装 |
| `tekika-ai-backend/backend/agent/memory.py` | SQLite会話履歴とChroma長期記憶 |
| `tekika-ai-backend/backend/tools/` | filesystem、Git、画像生成、plugin loader |
| `tekika-ai-frontend/src/app/page.tsx` | session/chat状態 |
| `tekika-ai-frontend/src/lib/api.ts` | HTTP/SSEクライアント |
| `tekika-ai-frontend/src/components/` | chat表示、tool event、FileTree等 |
| `setup-tekika.bat` | 初回セットアップ |
| `environment-checker.bat` | 環境チェック |
| `start-tekika.bat` | 起動 |

## 維持すべきAPI/UI契約

- Quality modeはtool callingを反復し、Speed modeは直接応答する。
- Providerごとの形式変換は各providerに閉じ、全providerでstreamingとtool callingの契約を保つ。
- Chat SSEは `delta`、`tool_event`、`done`、`error` を扱う。FrontendのReadableStream終端で完了通知を一度だけ呼ぶ。
- Abort時は通常の完了・エラー通知を重複発火させない。server側キャンセルとの整合は変更時に確認する。
- Retry/regenerateでは元のユーザー入力と履歴を使い、ユーザー発言を二重保存しない。
- filesystemの `list_directory` はentry一覧、`search_files` はファイルmetadata、`read_file` はUTF-8本文を返す。tool結果をUI表示に使う変更ではSSE eventから画面までデータを追う。
- UIは利用可能providerを選べる。READMEでは任意model選択はAPI拡張点で、現行UIはprovider既定モデルを使うと説明している。

## 設定と安全な取り扱い

- `.env` の `LLM_PROVIDER` は既定provider。クラウドproviderの利用には対応APIキーが必要。
- `.env`、DB、Chromaデータ、仮想環境、Node依存物、ビルド生成物はローカル状態として扱う。
- APIキーや認証情報をコード、ログ、handoff、commitに入れない。`.env.example`には秘密値を書かない。
- 配布ZIPは `make-distribution-zip.bat` を使い、`.env`や利用者データが混入しないことを確認する。

## セットアップと起動

- Windows: `setup-tekika.bat` で依存関係等を初期化し、`start-tekika.bat` でBackend (8000) とFrontend (3000) を起動。
- 手動起動: Backendは `tekika-ai-backend` から `python -m uvicorn backend.main:app --port 8000`。Frontendは `tekika-ai-frontend` から `npm install` 後 `npm run dev`。
- 利用者向けの詳細・環境要件・設定例はREADME.mdを先に確認する。

## 作業時の注意

- 実装を変える前に対象コードと呼び出し側を読み、既存の契約やREADMEの説明とのずれを確認する。
- Providerの共通処理を変える場合は4 providerすべてを確認する。SSEを変える場合はBackendのevent生成からFrontendの消費・表示まで追跡する。
- 変更後の確認方法は変更内容に合わせて選ぶ。未実行のテストを実行済みと記載しない。
- 未実装事項や現時点でのテスト状況は、ソースと実行結果を確認してから追記する。
