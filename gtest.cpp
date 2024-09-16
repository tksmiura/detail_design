/**
 * @file gtest.cpp
 * @brief google testのコード
 * @details
 *   * テスト対象はxxxドライバ
 *   * ドライバはno-OSで動作する
 */

#include "gtest/gtest.h"
#include "gmock/gmock.h"

extern int open_flag;

/**
 * デバイスのオープンを確認
 */
TEST_F(deviceTest, device_open_Normal)
{
	int ret = 0;

	/*- 前提条件: オープン済みフラグが0であること */
	open_flag = 0;

	/*- 確認項目: io_write32を(REG1_SET_VALUE, REG1_ADDR)で1度よばれること */\
	EXPECT_CALL(mock, io_write32(REG1_SET_VALUE, REG1_ADDR)).Times(1).WillOnce(Return(0u));

	/*- 実施内容:  device_openを引数(1, 0)で呼び出す */
	ret = device_open(1, 0);

	/*- 確認項目: device_openの戻値が0であること  */
	EXPECT_EQ(0, ret);
	/*- 確認項目: オープン済みフラグが1であること */
	EXPECT_EQ(1, open_flag);

	/*- 確認: これはエラーになる */

}

/**
 * デバイスのオープンの異常系を確認
 */
TEST_F(deviceTest, device_open_Error)
{
	int ret = 0;

	/*- 前提条件: オープン済みフラグが1であること */
	open_flag = 1;

	/*- 確認項目: io_write32を(REG1_SET_VALUE, REG1_ADDR)で1度よばれること */\
	EXPECT_CALL(mock, io_write32(REG1_SET_VALUE, REG1_ADDR)).Times(1).WillOnce(Return(0u));

	/*- 実施内容:  device_openを引数(1, 0)で呼び出す */
	ret = device_open(1, 0);

	/*- 確認項目: device_openの戻値が-EPERMであること  */
	EXPECT_EQ(-EPERM, ret);

}
