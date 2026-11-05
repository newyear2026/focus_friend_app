# Play Console 일회성 제품 등록표

Play Console → 수익 창출 → 제품 → 일회성 제품 → 만들기. 제품마다 구매 옵션 하나(유형: 구매/Buy)를 만들고 활성화합니다. 제품 ID는 한 번 만들면 바꾸거나 다시 쓸 수 없습니다. 이미지(512×512 PNG)는 콘솔에 이미지 칸이 있을 때만 씁니다.

| 제품 ID | 이미지 | 한국 | 멕시코 |
| --- | --- | --- | --- |
| `friend_otter` | [friend_otter.png](friend_otter.png) | ₩1,500 | MX$10 |
| `friend_squirrel` | [friend_squirrel.png](friend_squirrel.png) | ₩1,500 | MX$10 |
| `friend_fennec` | [friend_fennec.png](friend_fennec.png) | ₩1,500 | MX$10 |
| `remove_ads` | [remove_ads.png](remove_ads.png) | ₩1,000 | MX$10 |
| `all_friends` | [all_friends.png](all_friends.png) | ₩3,500 | MX$29 |

## 다섯 제품 공통 입력값

| 항목 | 값 |
| --- | --- |
| 구매 옵션 ID | `buy` |
| 구매 옵션 유형 | 구매(Buy). 대여(Rent)는 쓰지 않습니다. |
| 이전 버전과 호환(Backwards compatible) | 켬. 앱의 결제 라이브러리가 이 옵션의 가격을 읽습니다. |
| 여러 개 구매(Multi-quantity) | 끔 |
| 가격 | 기본 가격을 원화로 넣고 "국가/지역별 가격"에서 멕시코만 고칩니다. 나머지 국가는 자동 환산값을 둡니다. |
| 혜택(Offers) | 만들지 않음 |
| 상태 | 구매 옵션을 **활성화**해야 앱에 가격이 뜹니다. |

이름은 55자, 설명은 200자까지 들어갑니다. 아래 문구는 모두 그 안에 들어갑니다. 콘솔의 기본 언어로 먼저 입력하고, "번역 추가"로 나머지 언어를 넣습니다.

## friend_otter

| 언어 | 이름 | 설명 |
| --- | --- | --- |
| 한국어 | 해달 | 햇살 가득한 바닷가 방에서 함께 공부하는 해달 친구예요. |
| English | Otter | A sea otter friend who studies with you in a sunny seaside room. |
| Español | Nutria | Una nutria que estudia contigo en una habitación soleada junto al mar. |
| 日本語 | ラッコ | 日差しあふれる海辺の部屋で一緒に勉強するラッコの友だち。 |

## friend_squirrel

| 언어 | 이름 | 설명 |
| --- | --- | --- |
| 한국어 | 다람쥐 | 초록 숲속 기록방에서 함께 공부하는 다람쥐 친구예요. |
| English | Squirrel | A squirrel friend who studies with you in a green forest study. |
| Español | Ardilla | Una ardilla que estudia contigo en un estudio verde del bosque. |
| 日本語 | リス | 緑の森の記録部屋で一緒に勉強するリスの友だち。 |

## friend_fennec

| 언어 | 이름 | 설명 |
| --- | --- | --- |
| 한국어 | 사막여우 | 노을빛 사막 서재에서 함께 공부하는 사막여우 친구예요. |
| English | Fennec fox | A fennec fox friend who studies with you in a desert study at sunset. |
| Español | Zorro del desierto | Un zorro del desierto que estudia contigo en un estudio al atardecer. |
| 日本語 | フェネック | 夕焼けの砂漠の書斎で一緒に勉強するフェネックの友だち。 |

## remove_ads

| 언어 | 이름 | 설명 |
| --- | --- | --- |
| 한국어 | 광고 제거 | 기록과 설정 화면의 광고를 없애요. 한 번 결제로 계속 적용돼요. |
| English | Remove ads | Removes the ads in Records and Settings. One-time purchase. |
| Español | Quitar anuncios | Quita los anuncios de Registros y Ajustes. Pago único. |
| 日本語 | 広告を消す | 記録と設定画面の広告を消します。買い切りです。 |

## all_friends

| 언어 | 이름 | 설명 |
| --- | --- | --- |
| 한국어 | 모든 친구 묶음 | 해달·다람쥐·사막여우와 광고 제거를 함께 담았어요. 앞으로 나올 친구는 포함되지 않아요. |
| English | All friends bundle | Otter, squirrel and fennec fox, plus ad removal. Friends added later are sold separately. |
| Español | Paquete de todos los amigos | Nutria, ardilla y zorro del desierto, más quitar anuncios. Los amigos nuevos se venden aparte. |
| 日本語 | 友だち全員セット | ラッコ・リス・フェネックと広告を消す機能のセット。今後増える友だちは別売りです。 |
