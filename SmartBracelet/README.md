#  蓝牙第三方库使用纪要
1. AppleNotifyModel 苹果通知模式
2. BloodModel 血压
3. DataModel 记录蓝牙的唯一标识、地址、时间戳
4. DisplayUiModel 记录各种页面
5. DrinkModel 喝水/酒 等时长
6. FunctionListModel 功能清单
7. FunctionSwitchModel 功能开关设置
8. HeartModel 心跳功能
9. SleepModel 睡眠模式
10. SleepTimeModel 睡眠时间模式
11. StepModel 步行
12. 


easyRealm使用说明：
save: 
let pokemon = Pokemon()
try pokemon.er.save(update: true)
edit:
let pokemon = Pokemon()

try pokemon.er.edit {
  $0.level = 42
}
delete:
let pokemon = Pokemon(name: "Pikachu")
try pokemon.er.delete()
query:
let pokemons = try Pokemon.er.all()
let pokemon = Pokemon.er.fromRealm(with: "Pikachu")
