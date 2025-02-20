<?php

function SetupStore($location, $name, $mode) {
  $store = new CPStore();
  $store->Open($location, $name, $mode);
  return $store;
}

function SetupCertificates($location, $name, $mode) {
  $store = SetupStore($location, $name, $mode);
  return $store->get_Certificates();
}

function SetupCertificate(
  $location,
  $name,
  $mode,
  $find_type,
  $query,
  $valid_only,
  $number
) {
  $certs = SetupCertificates($location, $name, $mode);
  if (!is_null($find_type)) {
    $certs = $certs->Find($find_type, $query, $valid_only);
    if (is_string($certs))
      return $certs;
    else
      return $certs->Item($number);
  } else {
    $cert = $certs->Item($number);
    return $cert;
  }
}

try {
  printf("Выполнение скрипта...\n");

  // Get filename from first argument to the PHP script
  if (count($argv) < 2) {
    throw new Exception("Необходимо передать путь к файлу для подписания первым аргументом!");
  }
  $filename = $argv[1];
  if (!file_exists($filename)) {
    throw new Exception( "Файл $filename не найден!");
  }
  printf("Чтение файла $filename...\n");
  $content = file_get_contents($filename);
  printf("Чтение файла $filename: успешно!\n");

  printf("Получение сертификата...\n");
  $cert = SetupCertificate(
    CURRENT_USER_STORE,
    "My",
    STORE_OPEN_READ_ONLY,
    CERTIFICATE_FIND_SHA1_HASH,
    getenv("CRYPTOPRO_CERTIFICATE_PFX_FILE_HASH"),
    false,
    1
  );

  if (!$cert) {
    throw new Exception("Сертификат не найден!");
  }
  printf("Получение сертификата: успешно!\n");

  printf("Получение методов подписания...\n");
  $algoOid = $cert->PublicKey()->get_Algorithm()->get_Value();
  if ($algoOid === "1.2.643.7.1.1.1.1") { // алгоритм подписи ГОСТ Р 34.10-2012 с ключом 256 бит
    $signMethod = "urn:ietf:params:xml:ns:cpxmlsec:algorithms:gostr34102012-gostr34112012-256";
    $digestMethod = "urn:ietf:params:xml:ns:cpxmlsec:algorithms:gostr34112012-256";
  } elseif ($algoOid === "1.2.643.7.1.1.1.2") { // алгоритм подписи ГОСТ Р 34.10-2012 с ключом 512 бит
    $signMethod = "urn:ietf:params:xml:ns:cpxmlsec:algorithms:gostr34102012-gostr34112012-512";
    $digestMethod = "urn:ietf:params:xml:ns:cpxmlsec:algorithms:gostr34112012-512";
  } elseif ($algoOid === "1.2.643.2.2.19") { // алгоритм ГОСТ Р 34.10-2001
    $signMethod = "urn:ietf:params:xml:ns:cpxmlsec:algorithms:gostr34102001-gostr3411";
    $digestMethod = "urn:ietf:params:xml:ns:cpxmlsec:algorithms:gostr3411";
  } else {
    throw new ErrorException("Поддерживается XML подпись сертификатами только с алгоритмом ГОСТ Р 34.10-2012, ГОСТ Р 34.10-2001");
  }
  printf("Получение методов подписания: успешно!\n");

  printf("Вставка сертификата в XML...\n");
  $b64cert = $cert->Export(ENCODE_BASE64);
  $content = str_replace(
    ['%BASE64CERT%', '%SIGN_METHOD%', '%DIGEST_METHOD%'],
    [$b64cert, $signMethod, $digestMethod],
    $content
  );
  printf("Вставка сертификата в XML: успешно!\n");

  printf("Открытие сертификата для подписания...\n");
  $signer = new CPSigner();
  $signer->set_Certificate($cert);
  $signer->set_KeyPin(getenv("CRYPTOPRO_CERTIFICATE_PFX_FILE_PIN"));
  printf("Открытие сертификата для подписания: успешно!\n");

  printf("Создание объекта CAdESCOM.SignedXML...\n");
  $sd = new CPSignedXML();
  $sd->set_Content($content);
  $sd->set_SignatureMethod($signMethod);
  $sd->set_DigestMethod($digestMethod);
  $sd->set_SignatureType(XML_SIGNATURE_TYPE_TEMPLATE);
  printf("Создание объекта CAdESCOM.SignedXML: успешно!\n");

  printf("Подписание...\n");
  $content_signed = $sd->Sign($signer, '');
  printf("Подписание: успешно!\n");

  printf("Сохранение нового файла...\n");
  file_put_contents($filename . ".signed.xml", $content_signed);
  printf("Сохранение нового файла: успешно!\n");

  printf("Выполнение скрипта: успешно!\n");
} catch (Exception $e) {
  printf($e->getMessage() . "\n");
  return;
}

?>