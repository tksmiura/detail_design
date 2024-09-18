# 疑似言語の書き方を検討


## ダイクストラ法のサンプル(PRE、インデント)

https://ja.wikipedia.org/wiki/%E3%83%80%E3%82%A4%E3%82%AF%E3%82%B9%E3%83%88%E3%83%A9%E6%B3%95#%E6%93%AC%E4%BC%BC%E3%82%B3%E3%83%BC%E3%83%89

抜粋


```
// 初期化
for ( v ← V )
    d(v) ← ( v = s ならば0, それ以外は∞)
    ...

// 本計算
while ( Qが空集合ではない )
    u ← Q から d(u)が最小である頂点 u を取り除き取り出す
    for each ( u からの辺である各 v ∈ V )
        alt ← d(u) + length(u, v)
        if ( d(u) > alt )
           d(v) ← alt
           ...
```

## List

 * xxxxの条件の間、繰り返し
   * 処理１
   * もしyyyyなら、
      * 処理２
   * でなければ、
      * 処理３
 * ループを抜けた


## 引用

> xxxxの条件の間、繰り返し

>> 処理１

>> もしyyyyなら、

>>> 処理２

>> でなければ、

>>> 処理３

> ループを抜けた

## IPA疑似言語(PRE＋罫線)

```
・sumA ← 0
・sumB ← 0

■ I <= 100
│・処理
│▲
││・sumA ←  sum A + I
│┼───────────
││・sumB ←  sumB + I
│▼
│
■
```


## IPA疑似言語(引用＋バー)


* sumA ← 0
* sumB ← 0

■ I <= 100

> * 処理
>
> ▲ I　> 60
>>    * sumA ←  sum A + I
>> - - -
>>    * sumB ←  sumB + I
>
> ▼
> * I ← I + 1
>
 
■
