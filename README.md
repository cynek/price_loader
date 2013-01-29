price_loader
============

параметры config.ini
====================

* mailuser - почтовый ящик
* mailpassword - пароль
* mailhost - адрес сервера
* mailfolder imap папка с письмами от поставщиков (по-умолчанию INBOX)
* mailport - порт подключения к imap серверу (по-умолчанию 993)

параметры конфигурации поставщиков (./iniz/*.ini)
=================================================

# Email
  * usemail - 0/1 использовать ли почту
  * mailfrom - email поставщика

# Web
  * useauth - 0/1 использовать ли авторизацию (Web)
  * authpage - страница авторизации
  * loadpage - страница поиска ссылки на прайс
  * formauth - css selector формы авторизации
  * formlogin - поле логина на форме
  * formpassword - поле пароля на форме
  * login - сам логин
  * password - и пароль
  * filename - шаблон поиска ссылки (* - любые символы, $ - любой сивол)
  * filenameinner = шаблон поиска файла внутри архива (* - любые символы, $ - любой сивол)

# Для предотвращения проблем с http://autokontinent.ru/price:
``> sudo patch /usr/share/perl5/Net/HTTP/Methods.pm  ./Methods.pm.patch``
