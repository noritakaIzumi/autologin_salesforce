# ワンタッチでSalesforceの打刻(定時出社)をしてくれるアプリ - v2.2chrome

-   GitHubリポジトリ

    [noritakaIzumi/autologin_salesforce: Automatically Login to Salesforce](https://github.com/noritakaIzumi/autologin_salesforce)

### Update History

-   2019/3/27 (v2.2.1)

    -   README.mdを修正

-   2019/3/27 (v2.1 & v2.2)

    -   ドメインをユーザー名から直接入力する仕様に変更
    -   パスワード暗号化のリトライ機能を廃止 (失敗したときは再入力でお願いいたします)

-   2019/3/19 (v2.0)

    -   ログ機能を実装
    -   パスワードを暗号化する機能を実装

-   2019/3/6 (v1.0)

    -   初版公開

## Contents

-   encrypt.rb (ユーザー名・パスワードの初期設定スクリプト)
-   autologin_salesforce.rb (打刻を行うRubyスクリプト)
-   is_morning_then_autologin.sh (朝の時間帯にのみRubyスクリプトを実行するよう制御するスクリプト)

## Develop Environment

-   Ruby

    ```text
    $ ruby -v
    ruby 2.5.3p105 (2018-10-18 revision 65156) [x64-mingw32]
    ```

-   ChromeDriver

    ```text
    $ chromedriver --version
    ChromeDriver 73.0.3683.20 (8e2b610813e167eee3619ac4ce6e42e3ec622017)
    ```

## 必要なもの

-   Ruby (and selenium-driver)
-   Google Chrome
-   ChromeDriver

## 事前準備 (わかりにくいかもしれない，要修正)

1.  Prepare Ruby
2.  Prepare ChromeDriver
3.  Config Username and Password
4.  Copy Scripts to Startup

### 1. Prepare Ruby

-   Rubyのダウンロード

    [Downloads](https://rubyinstaller.org/downloads/)

-   Rubyのインストールとちょっとした環境構築

    参考: [Rubyのダウンロードとインストール Ruby入門 RubyLife](https://www.javadrive.jp/ruby/install/index1.html)

-   selenium-driverのインストール

    ```bash
    gem install selenium-webdriver
    ```

### 2. Prepare ChromeDriver

-   ChromeDriverのインストール

    [Install ChromeDriver](https://chromedriver.storage.googleapis.com/index.html?path=73.0.3683.20/)

-   Rubyのbinフォルダ配下に置くか，またはお好きな場所に配置してPATHを通す

### 3. Config Username and Password

-   encrypt.rbを実行

    ```bash
    ruby encrypt.rb
    ```

-   ユーザ名・パスワードを入力

    ```text
    User Name: foo_bar@hoge.co.jp
    Password: ********
    Password again: ********
    ```

-   入力内容を確認し，問題なければ`Y`，再入力は`R`をタイプ

-   コンフィグファイル保存場所を選択

    -   現在はカレントディレクトリ・親ディレクトリのみサポートされています

-   パスワードの暗号化等を行い，ファイルに出力します

    -   暗号化の段階でかなりの頻度で失敗する現象が発生中 (もし失敗しても優しい目で再実行してあげてください...)

### 4. Copy Scripts to Startup

-   is_morning_then_autologin.shをスタートアップフォルダに配置

    -   このスクリプトの実行時間が06:00～08:59のときのみ，Rubyスクリプトが実行される
    -   このスクリプトを使わず，autologin_salesforce.rbを手動実行してもよい

## autologin_salesforce.rbの手動実行方法について

-   実行コマンド

    ```bash
    ruby autologin_salesforce.rb [option]
    ```

-   オプションには打刻の種類を記載します(省略すると退社モードで実行します)

    -   出社: arrival
    -   退社: leaving
    -   定時出社: regular_arrival
    -   定時退社: regular_leaving

-   実行するとブラウザが画面最大化で開き，salesforceにログイン
→打刻ボタンを押下→「勤務表」タブを表示(打刻されていることを確認できる)
→ログアウト→ブラウザを閉じる

    -   ソースコードをいじれば，ヘッドレスモードで実行することも可能です

-   退社・定時退社モードで実行すると，「勤務表」に遷移後，3分間スリープしますので，
その間に工数の入力を行ってください

-   ログファイルがlog/execute_logsに出力されています (役に立つかどうかわからない)

## Others

-   他言語での実装歓迎
-   将来的にはC++で実装してexe化したい...
