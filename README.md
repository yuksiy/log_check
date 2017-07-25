# log_check

## 概要

ログファイルの内容をチェック

## 使用方法

### log_check.sh

ログファイルに失敗メッセージ (例えば「Warning」と「Error」) が
出力されていないことをチェックします。

    $ log_check.sh -F "Warning" -F "Error" ログファイル名

ログファイルに終了メッセージ (例えば「All tasks ended successfully.」) が
出力されていることをチェックします。

    $ log_check.sh -E "All tasks ended successfully." ログファイル名

### その他

* 上記で紹介したツールの詳細については、「ツール名 --help」を参照してください。

## 動作環境

OS:

* Linux
* Cygwin

依存パッケージ または 依存コマンド:

* make (インストール目的のみ)
* realpath
* [nkf](https://osdn.net/projects/nkf/)

## インストール

ソースからインストールする場合:

    (Linux, Cygwin の場合)
    # make install

fil_pkg.plを使用してインストールする場合:

[fil_pkg.pl](https://github.com/yuksiy/fil_tools_pl/blob/master/README.md#fil_pkgpl) を参照してください。

## インストール後の設定

環境変数「PATH」にインストール先ディレクトリを追加してください。

## 最新版の入手先

<https://github.com/yuksiy/log_check>

## License

MIT License. See [LICENSE](https://github.com/yuksiy/log_check/blob/master/LICENSE) file.

## Copyright

Copyright (c) 2004-2017 Yukio Shiiya
