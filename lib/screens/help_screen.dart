import 'package:flutter/material.dart';

class HelpScreen extends StatelessWidget {
  const HelpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Помощь'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'Часто задаваемые вопросы',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 16),
          const ExpansionTile(
            title: Text('Как забронировать поездку?'),
            children: [
              Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  'Чтобы забронировать поездку:\n'
                  '1. Выберите подходящую поездку из списка\n'
                  '2. Нажмите кнопку "Забронировать"\n'
                  '3. Подтвердите бронирование\n'
                  '4. Ожидайте подтверждения от водителя',
                ),
              ),
            ],
          ),
          const ExpansionTile(
            title: Text('Как стать водителем?'),
            children: [
              Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  'Чтобы стать водителем:\n'
                  '1. Перейдите в настройки профиля\n'
                  '2. Выберите "Стать водителем"\n'
                  '3. Заполните необходимые документы\n'
                  '4. Дождитесь проверки документов',
                ),
              ),
            ],
          ),
          const ExpansionTile(
            title: Text('Как работает бонусная программа?'),
            children: [
              Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  'За каждую поездку вы получаете бонусные баллы:\n'
                  '• 10% от стоимости поездки для пассажиров\n'
                  '• 5% от стоимости поездки для водителей\n'
                  'Баллы можно использовать для оплаты будущих поездок',
                ),
              ),
            ],
          ),
          const ExpansionTile(
            title: Text('Как отменить поездку?'),
            children: [
              Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  'Отменить поездку можно:\n'
                  '1. В списке ваших поездок\n'
                  '2. На экране деталей поездки\n'
                  'Бесплатная отмена доступна за 24 часа до начала поездки',
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Нужна дополнительная помощь?',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Свяжитесь с нашей службой поддержки:',
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      const Icon(Icons.email, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'support@atlas-app.ru',
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.phone, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        '+7 (800) 123-45-67',
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
} 