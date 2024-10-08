/**
 * @file test.c
 * @brief テストモジュール
 * @details
 *   * ファイルの説明１
 *   * ファイルの説明２
 */

#include <stdio.h>

/**
 * 型定義
 */
typedef unsigned int u32;

/**
 * 構造体型定義
 */
typedef struct _x {
    int x;         /**< 横 */
} X;

/**
 * 構造体
 */
struct test {
    int x[xx];     /**< 横 */
    int y;         /**< 縦 */
};

/**
 * バッファ
 */
char buffer[100];

/**
 * メイン関数
 * @param [in] argc : 引数の個数
 * @param      argv : 引数文字列の配列
 * @return 正常に終わったかどうかを返す
 * @retval 0: 正常終了
 * @retval 1: エラー
 * @details
 *       * 関数の説明１
 *       * 関数の説明２
 */
int main(int argc,
         char* argv[])
{
    int i;

    /*- 開始メッセージを印字する */
    printf("Hello world!\n");

    /*- 条件分岐 */
    if (argc > 1) {
        /*- もし１より大きければ、
         *  以下を繰り返す。      */
        for(i=0; i < argc; i++) {
            /*- 引数を印字 */
            printf("argc[%d]=%s\n", i, argv[i]);
        }

    } else {
        /*- それ以外は、異常終了する */
        return 1;
    }

    /*- 正常終了する */
    return 0;
}
