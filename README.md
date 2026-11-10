Pour reconstruire votre repo executer les scripts present dans src dans l'ordre des index.

~~~
./src/00-... <fingerprint>
...
./src/90-... 
~~~
Pour avoir le fingerprint : gpg --list-secret-key et recuperer le truc dans pub.