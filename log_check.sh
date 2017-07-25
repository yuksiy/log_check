#!/bin/sh

# ==============================================================================
#   機能
#     ログファイルの内容をチェックする
#   構文
#     USAGE 参照
#
#   Copyright (c) 2004-2017 Yukio Shiiya
#
#   This software is released under the MIT License.
#   https://opensource.org/licenses/MIT
# ==============================================================================

######################################################################
# 基本設定
######################################################################
trap "" 28				# TRAP SET
trap "POST_PROCESS;exit 1" 1 2 15	# TRAP SET

SCRIPT_FULL_NAME=`realpath $0`
SCRIPT_ROOT=`dirname ${SCRIPT_FULL_NAME}`
SCRIPT_NAME=`basename ${SCRIPT_FULL_NAME}`
PID=$$

LANG=ja_JP.UTF-8

######################################################################
# 関数定義
######################################################################
PRE_PROCESS() {
	# 一時ディレクトリの作成
	mkdir -p "${SCRIPT_TMP_DIR}"
}

POST_PROCESS() {
	# 一時ディレクトリの削除
	if [ ! ${DEBUG} ];then
		rm -fr "${SCRIPT_TMP_DIR}"
	fi
}

USAGE() {
	cat <<- EOF 1>&2
		Usage:
		    log_check.sh [OPTIONS ...] LOG_FILE
		
		    LOG_FILE : Specify a log file to check.
		
		OPTIONS:
		    -F FAIL_MSG_PATTERN
		       If you are going to check the fail messages,
		       specify the pattern.
		       You may use as many -F options on the command line
		       as you like to build up the list of messages to check.
		
		    -E END_MSG_PATTERN
		       If you are going to check the end messages,
		       specify the pattern.
		       You may use as many -E options on the command line
		       as you like to build up the list of messages to check.
		    --help
		       Display this help and exit.
	EOF
}

CMD() {
	(eval "$*")
	return
}

######################################################################
# 変数定義
######################################################################
FAIL_MSG_PATTERN=""
END_MSG_PATTERN=""

EXTCODE2INT="nkf -w -x"
INTCODE2EXT="nkf -w -x"
LOGCODE2INT="nkf -w -x"
GREP="grep"
GREP_OPTIONS=""

#DEBUG=TRUE
TMP_DIR="/tmp"
SCRIPT_TMP_DIR="${TMP_DIR}/${SCRIPT_NAME}.${PID}"
LOG_FILE_TMP="${SCRIPT_TMP_DIR}/log.tmp"

######################################################################
# メインルーチン
######################################################################

# オプションのチェック
CMD_ARG="`getopt -o F:E: -l help -- \"$@\" 2>&1`"
if [ $? -ne 0 ];then
	echo "-E ${CMD_ARG}" 1>&2
	USAGE;exit 1
fi
eval set -- "${CMD_ARG}"
while true ; do
	opt="$1"
	case "${opt}" in
	-F)
		FAIL_MSG_PATTERN="${FAIL_MSG_PATTERN} -e \"`echo \"$2\" | ${EXTCODE2INT}`\""
		shift 2
		;;
	-E)
		END_MSG_PATTERN="${END_MSG_PATTERN} -e \"`echo \"$2\" | ${EXTCODE2INT}`\""
		shift 2
		;;
	--help)
		USAGE;exit 0
		;;
	--)
		shift 1;break
		;;
	esac
done

# オプションの整合性チェック
# -F と-E のうち、両方とも指定された場合
if [ \( ! "${FAIL_MSG_PATTERN}" = "" \) -a \( ! "${END_MSG_PATTERN}" = "" \) ];then
	echo "-E Specify only one of \"-F\" and \"-E\" option" 1>&2
	USAGE;exit 1
fi
# -F と-E のうち、両方とも指定されなかった場合
if [ \( "${FAIL_MSG_PATTERN}" = "" \) -a \( "${END_MSG_PATTERN}" = "" \) ];then
	echo "-E Specify at least one of \"-F\" and \"-E\" option" 1>&2
	USAGE;exit 1
fi

# 第1引数のチェック
if [ "$1" = "" ];then
	echo "-E Missing LOG_FILE argument" 1>&2
	USAGE;exit 1
else
	LOG_FILE=$1
	# ログファイルのチェック
	if [ ! -f "${LOG_FILE}" ];then
		echo "-E LOG_FILE not a file -- \"${LOG_FILE}\"" 1>&2
		#USAGE;exit 1
		exit 1
	fi
fi

# 作業開始前処理
PRE_PROCESS

# 一時ログファイルのコード変換
cat "${LOG_FILE}" | ${LOGCODE2INT} > "${LOG_FILE_TMP}"
if [ $? -ne 0 ];then
	echo "-E Command has ended unsuccessfully." 1>&2
	# 作業終了後処理
	POST_PROCESS;exit 1
fi

################
# メインループ #
################

# 失敗メッセージチェック
if [ ! "${FAIL_MSG_PATTERN}" = "" ];then
	LC=`CMD "cat \"${LOG_FILE_TMP}\" | ${GREP} ${GREP_OPTIONS} -c ${FAIL_MSG_PATTERN}"`
	# 失敗メッセージ数 = 0
	if [ ${LC} -eq 0 ]; then
		#cat <<- EOF
		#	-I Fail message check has ended successfully. -- "${LOG_FILE}"
		#EOF
		cat <<- EOF | ${INTCODE2EXT}
			-I 失敗メッセージチェックが正常終了しました -- "${LOG_FILE}"
		EOF
		# 作業終了後処理
		POST_PROCESS;exit 0
	# 失敗メッセージ数 >= 1
	elif [ ${LC} -ge 1 ]; then
		#cat <<- EOF 1>&2
		#	-E Fail message was detected. -- "${LOG_FILE}"
		#	     fail message count : ${LC}
		#	   Please investigate a cause.
		#EOF
		cat <<- EOF | ${INTCODE2EXT} 1>&2
			-E 失敗メッセージが検出されました -- "${LOG_FILE}"
			     失敗メッセージ数 : ${LC}
			   原因を調査してください
		EOF
		# 作業終了後処理
		POST_PROCESS;exit 1
	fi
# 終了メッセージチェック
elif [ ! "${END_MSG_PATTERN}" = "" ];then
	LC=`CMD "cat \"${LOG_FILE_TMP}\" | ${GREP} ${GREP_OPTIONS} -c ${END_MSG_PATTERN}"`
	# 終了メッセージ数 = 1
	if [ ${LC} -eq 1 ]; then
		#cat <<- EOF
		#	-I End message check has ended successfully. -- "${LOG_FILE}"
		#EOF
		cat <<- EOF | ${INTCODE2EXT}
			-I 終了メッセージチェックが正常終了しました -- "${LOG_FILE}"
		EOF
		# 作業終了後処理
		POST_PROCESS;exit 0
	# 終了メッセージ数 = 0
	elif [ ${LC} -eq 0 ]; then
		#cat <<- EOF 1>&2
		#	-E End message was not detected. -- "${LOG_FILE}"
		#	   Please investigate a cause.
		#EOF
		cat <<- EOF | ${INTCODE2EXT} 1>&2
			-E 終了メッセージが検出されませんでした -- "${LOG_FILE}"
			   原因を調査してください
		EOF
		# 作業終了後処理
		POST_PROCESS;exit 1
	# 終了メッセージ数 >= 2
	elif [ ${LC} -ge 2 ]; then
		#cat <<- EOF 1>&2
		#	-W Two or more end message was detected. -- "${LOG_FILE}"
		#	     end message count : ${LC}
		#	   Please investigate a cause.
		#EOF
		cat <<- EOF | ${INTCODE2EXT} 1>&2
			-W 終了メッセージが2個以上検出されました -- "${LOG_FILE}"
			     終了メッセージ数 : ${LC}
			   原因を調査してください
		EOF
		# 作業終了後処理
		POST_PROCESS;exit 1
	fi
fi

