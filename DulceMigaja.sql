-- MySQL dump 10.13  Distrib 8.0.42, for Win64 (x86_64)
--
-- Host: localhost    Database: dulce_migaja
-- ------------------------------------------------------
-- Server version	8.1.0

/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!50503 SET NAMES utf8 */;
/*!40103 SET @OLD_TIME_ZONE=@@TIME_ZONE */;
/*!40103 SET TIME_ZONE='+00:00' */;
/*!40014 SET @OLD_UNIQUE_CHECKS=@@UNIQUE_CHECKS, UNIQUE_CHECKS=0 */;
/*!40014 SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0 */;
/*!40101 SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='NO_AUTO_VALUE_ON_ZERO' */;
/*!40111 SET @OLD_SQL_NOTES=@@SQL_NOTES, SQL_NOTES=0 */;

--
-- Table structure for table `ajustes_inventario`
--

DROP TABLE IF EXISTS `ajustes_inventario`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `ajustes_inventario` (
  `id_ajuste` int NOT NULL AUTO_INCREMENT,
  `tipo_inventario` enum('materia_prima','producto_terminado') NOT NULL,
  `id_referencia` int NOT NULL,
  `cantidad_anterior` decimal(12,4) NOT NULL,
  `cantidad_nueva` decimal(12,4) NOT NULL,
  `motivo` text NOT NULL,
  `autorizado_por` int NOT NULL,
  `creado_en` datetime NOT NULL,
  PRIMARY KEY (`id_ajuste`),
  KEY `autorizado_por` (`autorizado_por`),
  CONSTRAINT `ajustes_inventario_ibfk_1` FOREIGN KEY (`autorizado_por`) REFERENCES `usuarios` (`id_usuario`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `ajustes_inventario`
--

LOCK TABLES `ajustes_inventario` WRITE;
/*!40000 ALTER TABLE `ajustes_inventario` DISABLE KEYS */;
/*!40000 ALTER TABLE `ajustes_inventario` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `alembic_version`
--

DROP TABLE IF EXISTS `alembic_version`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `alembic_version` (
  `version_num` varchar(32) NOT NULL,
  PRIMARY KEY (`version_num`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `alembic_version`
--

LOCK TABLES `alembic_version` WRITE;
/*!40000 ALTER TABLE `alembic_version` DISABLE KEYS */;
INSERT INTO `alembic_version` VALUES ('9c390faeb787');
/*!40000 ALTER TABLE `alembic_version` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `caja_productos`
--

DROP TABLE IF EXISTS `caja_productos`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `caja_productos` (
  `id_caja_producto` int NOT NULL AUTO_INCREMENT,
  `id_caja` int NOT NULL,
  `id_producto` int NOT NULL COMMENT 'FK a productos (pan terminado)',
  `cantidad` tinyint NOT NULL COMMENT 'Piezas de este producto en la caja',
  PRIMARY KEY (`id_caja_producto`),
  UNIQUE KEY `uq_caja_prod` (`id_caja`,`id_producto`),
  KEY `fk_cajaprod_caja` (`id_caja`),
  KEY `fk_cajaprod_producto` (`id_producto`),
  CONSTRAINT `fk_cajaprod_caja` FOREIGN KEY (`id_caja`) REFERENCES `cajas` (`id_caja`) ON DELETE CASCADE,
  CONSTRAINT `fk_cajaprod_producto` FOREIGN KEY (`id_producto`) REFERENCES `productos` (`id_producto`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci COMMENT='Composición de cada caja: qué productos lleva y cuántas piezas.';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `caja_productos`
--

LOCK TABLES `caja_productos` WRITE;
/*!40000 ALTER TABLE `caja_productos` DISABLE KEYS */;
/*!40000 ALTER TABLE `caja_productos` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `cajas`
--

DROP TABLE IF EXISTS `cajas`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `cajas` (
  `id_caja` int NOT NULL AUTO_INCREMENT,
  `uuid_caja` varchar(36) NOT NULL,
  `nombre` varchar(120) NOT NULL COMMENT 'Ej: Caja Mixta Concha+Dona Chica',
  `descripcion` text,
  `id_tamanio` int NOT NULL COMMENT 'FK a tamanios_charola',
  `tipo` enum('simple','mixta','triple') NOT NULL DEFAULT 'simple' COMMENT 'simple = 1 tipo; mixta = 2 tipos; triple = 3 tipos (solo charola grande)',
  `precio_venta` decimal(10,2) NOT NULL DEFAULT '0.00',
  `estatus` enum('activo','inactivo') NOT NULL DEFAULT 'activo',
  `creado_en` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `actualizado_en` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `creado_por` int DEFAULT NULL,
  PRIMARY KEY (`id_caja`),
  UNIQUE KEY `uq_uuid_caja` (`uuid_caja`),
  KEY `fk_caja_tamanio` (`id_tamanio`),
  KEY `fk_caja_creado_por` (`creado_por`),
  CONSTRAINT `fk_caja_creado_por` FOREIGN KEY (`creado_por`) REFERENCES `usuarios` (`id_usuario`) ON DELETE SET NULL,
  CONSTRAINT `fk_caja_tamanio` FOREIGN KEY (`id_tamanio`) REFERENCES `tamanios_charola` (`id_tamanio`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci COMMENT='Catálogo de cajas de pan disponibles para venta.';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `cajas`
--

LOCK TABLES `cajas` WRITE;
/*!40000 ALTER TABLE `cajas` DISABLE KEYS */;
/*!40000 ALTER TABLE `cajas` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `compras`
--

DROP TABLE IF EXISTS `compras`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `compras` (
  `id_compra` int NOT NULL AUTO_INCREMENT,
  `folio` varchar(20) NOT NULL,
  `id_proveedor` int NOT NULL,
  `fecha_compra` date NOT NULL,
  `total` decimal(12,2) NOT NULL,
  `observaciones` text,
  `creado_en` datetime NOT NULL,
  `creado_por` int DEFAULT NULL,
  PRIMARY KEY (`id_compra`),
  UNIQUE KEY `folio` (`folio`),
  KEY `id_proveedor` (`id_proveedor`),
  KEY `creado_por` (`creado_por`),
  CONSTRAINT `compras_ibfk_2` FOREIGN KEY (`id_proveedor`) REFERENCES `proveedores` (`id_proveedor`),
  CONSTRAINT `compras_ibfk_3` FOREIGN KEY (`creado_por`) REFERENCES `usuarios` (`id_usuario`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `compras`
--

LOCK TABLES `compras` WRITE;
/*!40000 ALTER TABLE `compras` DISABLE KEYS */;
/*!40000 ALTER TABLE `compras` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `cortes_diarios`
--

DROP TABLE IF EXISTS `cortes_diarios`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `cortes_diarios` (
  `id_corte` int NOT NULL AUTO_INCREMENT,
  `fecha_corte` date NOT NULL,
  `total_ventas` decimal(12,2) NOT NULL,
  `total_tickets` int NOT NULL,
  `total_piezas` decimal(12,2) NOT NULL,
  `efectivo` decimal(12,2) NOT NULL,
  `tarjeta` decimal(12,2) NOT NULL,
  `transferencia` decimal(12,2) NOT NULL,
  `cancelaciones` int NOT NULL,
  `estado` enum('abierto','cerrado') NOT NULL,
  `cerrado_por` int DEFAULT NULL,
  `cerrado_en` datetime DEFAULT NULL,
  `creado_en` datetime NOT NULL,
  PRIMARY KEY (`id_corte`),
  UNIQUE KEY `fecha_corte` (`fecha_corte`),
  KEY `cerrado_por` (`cerrado_por`),
  CONSTRAINT `cortes_diarios_ibfk_1` FOREIGN KEY (`cerrado_por`) REFERENCES `usuarios` (`id_usuario`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `cortes_diarios`
--

LOCK TABLES `cortes_diarios` WRITE;
/*!40000 ALTER TABLE `cortes_diarios` DISABLE KEYS */;
/*!40000 ALTER TABLE `cortes_diarios` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `detalle_compras`
--

DROP TABLE IF EXISTS `detalle_compras`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `detalle_compras` (
  `id_detalle_compra` int NOT NULL AUTO_INCREMENT,
  `id_compra` int NOT NULL,
  `id_materia` int NOT NULL,
  `cantidad_comprada` decimal(12,4) NOT NULL,
  `unidad_compra` varchar(20) NOT NULL,
  `factor_conversion` decimal(12,4) NOT NULL,
  `cantidad_base` decimal(12,4) NOT NULL,
  `costo_unitario` decimal(12,4) NOT NULL,
  `id_unidad_presentacion` int DEFAULT NULL,
  PRIMARY KEY (`id_detalle_compra`),
  KEY `id_compra` (`id_compra`),
  KEY `id_materia` (`id_materia`),
  KEY `id_unidad_presentacion` (`id_unidad_presentacion`),
  CONSTRAINT `detalle_compras_ibfk_1` FOREIGN KEY (`id_compra`) REFERENCES `compras` (`id_compra`) ON DELETE CASCADE,
  CONSTRAINT `detalle_compras_ibfk_2` FOREIGN KEY (`id_materia`) REFERENCES `materias_primas` (`id_materia`),
  CONSTRAINT `detalle_compras_ibfk_3` FOREIGN KEY (`id_unidad_presentacion`) REFERENCES `unidades_presentacion` (`id_unidad`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `detalle_compras`
--

LOCK TABLES `detalle_compras` WRITE;
/*!40000 ALTER TABLE `detalle_compras` DISABLE KEYS */;
/*!40000 ALTER TABLE `detalle_compras` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `detalle_pedidos`
--

DROP TABLE IF EXISTS `detalle_pedidos`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `detalle_pedidos` (
  `id_detalle` int NOT NULL AUTO_INCREMENT,
  `id_pedido` int NOT NULL,
  `id_producto` int NOT NULL,
  `cantidad` decimal(10,2) NOT NULL,
  `precio_unitario` decimal(10,2) NOT NULL COMMENT 'Precio al momento del pedido',
  `subtotal` decimal(12,2) NOT NULL,
  PRIMARY KEY (`id_detalle`),
  KEY `fk_detped_pedido` (`id_pedido`),
  KEY `fk_detped_producto` (`id_producto`),
  KEY `idx_detped_pedido` (`id_pedido`),
  KEY `idx_detped_pedido_producto` (`id_pedido`,`id_producto`),
  CONSTRAINT `fk_detped_pedido` FOREIGN KEY (`id_pedido`) REFERENCES `pedidos` (`id_pedido`) ON DELETE CASCADE,
  CONSTRAINT `fk_detped_producto` FOREIGN KEY (`id_producto`) REFERENCES `productos` (`id_producto`) ON DELETE RESTRICT
) ENGINE=InnoDB AUTO_INCREMENT=10 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Líneas de productos dentro de un pedido';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `detalle_pedidos`
--

LOCK TABLES `detalle_pedidos` WRITE;
/*!40000 ALTER TABLE `detalle_pedidos` DISABLE KEYS */;
INSERT INTO `detalle_pedidos` VALUES (1,1,4,4.00,28.00,112.00),(2,1,12,5.00,20.00,100.00),(3,2,1,6.00,24.00,144.00),(4,2,2,1.00,26.00,26.00),(5,2,4,1.00,28.00,28.00),(6,3,12,4.00,20.00,80.00),(7,4,1,4.00,24.00,96.00),(8,4,2,4.00,26.00,104.00),(9,4,3,4.00,26.00,104.00);
/*!40000 ALTER TABLE `detalle_pedidos` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `detalle_produccion`
--

DROP TABLE IF EXISTS `detalle_produccion`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `detalle_produccion` (
  `id_det_prod` int NOT NULL AUTO_INCREMENT,
  `id_produccion` int NOT NULL,
  `id_materia` int NOT NULL,
  `cantidad_requerida` decimal(12,4) NOT NULL,
  `cantidad_descontada` decimal(12,4) NOT NULL,
  PRIMARY KEY (`id_det_prod`),
  KEY `id_materia` (`id_materia`),
  KEY `id_produccion` (`id_produccion`),
  CONSTRAINT `detalle_produccion_ibfk_1` FOREIGN KEY (`id_materia`) REFERENCES `materias_primas` (`id_materia`),
  CONSTRAINT `detalle_produccion_ibfk_2` FOREIGN KEY (`id_produccion`) REFERENCES `produccion` (`id_produccion`) ON DELETE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=11 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `detalle_produccion`
--

LOCK TABLES `detalle_produccion` WRITE;
/*!40000 ALTER TABLE `detalle_produccion` DISABLE KEYS */;
INSERT INTO `detalle_produccion` VALUES (2,5,1,1000.0000,1000.0000),(3,5,2,240.0000,240.0000),(4,5,3,160.0000,160.0000),(5,5,4,300.0000,300.0000),(6,5,5,16.0000,16.0000),(7,5,6,200.0000,200.0000),(8,5,7,10.0000,10.0000),(9,5,8,10.0000,10.0000),(10,5,13,480.0000,480.0000);
/*!40000 ALTER TABLE `detalle_produccion` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `detalle_recetas`
--

DROP TABLE IF EXISTS `detalle_recetas`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `detalle_recetas` (
  `id_detalle_receta` int NOT NULL AUTO_INCREMENT,
  `id_receta` int NOT NULL,
  `id_materia` int NOT NULL,
  `cantidad_requerida` decimal(12,4) NOT NULL,
  `orden` smallint NOT NULL,
  `id_unidad_presentacion` int DEFAULT NULL,
  `cantidad_presentacion` decimal(12,4) DEFAULT NULL,
  PRIMARY KEY (`id_detalle_receta`),
  UNIQUE KEY `uq_det_receta_materia` (`id_receta`,`id_materia`),
  KEY `id_materia` (`id_materia`),
  KEY `id_unidad_presentacion` (`id_unidad_presentacion`),
  CONSTRAINT `detalle_recetas_ibfk_1` FOREIGN KEY (`id_materia`) REFERENCES `materias_primas` (`id_materia`),
  CONSTRAINT `detalle_recetas_ibfk_2` FOREIGN KEY (`id_receta`) REFERENCES `recetas` (`id_receta`) ON DELETE CASCADE,
  CONSTRAINT `detalle_recetas_ibfk_3` FOREIGN KEY (`id_unidad_presentacion`) REFERENCES `unidades_presentacion` (`id_unidad`) ON DELETE SET NULL
) ENGINE=InnoDB AUTO_INCREMENT=490 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `detalle_recetas`
--

LOCK TABLES `detalle_recetas` WRITE;
/*!40000 ALTER TABLE `detalle_recetas` DISABLE KEYS */;
INSERT INTO `detalle_recetas` VALUES (1,1,1,500.0000,1,NULL,NULL),(2,1,2,120.0000,2,NULL,NULL),(3,1,3,80.0000,3,NULL,NULL),(4,1,4,150.0000,4,NULL,NULL),(5,1,6,100.0000,5,NULL,NULL),(6,1,5,8.0000,6,NULL,NULL),(7,1,7,5.0000,7,NULL,NULL),(8,1,8,5.0000,8,NULL,NULL),(9,1,13,240.0000,9,NULL,NULL),(19,3,1,550.0000,1,NULL,NULL),(20,3,2,80.0000,2,NULL,NULL),(21,3,3,200.0000,3,NULL,NULL),(22,3,4,120.0000,4,NULL,NULL),(23,3,6,100.0000,5,NULL,NULL),(24,3,5,8.0000,6,NULL,NULL),(25,3,7,6.0000,7,NULL,NULL),(26,3,12,210.0000,8,NULL,NULL),(27,3,11,210.0000,9,NULL,NULL),(28,4,1,450.0000,1,NULL,NULL),(29,4,2,100.0000,2,NULL,NULL),(30,4,3,60.0000,3,NULL,NULL),(31,4,4,160.0000,4,NULL,NULL),(32,4,6,100.0000,5,NULL,NULL),(33,4,5,8.0000,6,NULL,NULL),(34,4,7,5.0000,7,NULL,NULL),(35,4,9,30.0000,8,NULL,NULL),(36,4,15,250.0000,9,NULL,NULL),(37,5,1,550.0000,1,NULL,NULL),(38,5,2,70.0000,2,NULL,NULL),(39,5,3,200.0000,3,NULL,NULL),(40,5,4,120.0000,4,NULL,NULL),(41,5,6,100.0000,5,NULL,NULL),(42,5,5,8.0000,6,NULL,NULL),(43,5,7,6.0000,7,NULL,NULL),(44,5,16,280.0000,8,NULL,NULL),(45,6,1,400.0000,1,NULL,NULL),(46,6,2,80.0000,2,NULL,NULL),(47,6,3,180.0000,3,NULL,NULL),(48,6,6,60.0000,4,NULL,NULL),(49,6,7,3.0000,5,NULL,NULL),(50,6,8,4.0000,6,NULL,NULL),(51,6,20,50.0000,7,NULL,NULL),(52,6,17,200.0000,8,NULL,NULL),(53,7,1,500.0000,1,NULL,NULL),(54,7,2,60.0000,2,NULL,NULL),(55,7,3,80.0000,3,NULL,NULL),(56,7,4,180.0000,4,NULL,NULL),(57,7,6,80.0000,5,NULL,NULL),(58,7,5,10.0000,6,NULL,NULL),(59,7,7,6.0000,7,NULL,NULL),(60,7,10,15.0000,8,NULL,NULL),(61,7,18,200.0000,9,NULL,NULL),(62,8,1,300.0000,1,NULL,NULL),(63,8,9,80.0000,2,NULL,NULL),(64,8,2,120.0000,3,NULL,NULL),(65,8,3,150.0000,4,NULL,NULL),(66,8,6,200.0000,5,NULL,NULL),(67,8,7,3.0000,6,NULL,NULL),(68,8,13,150.0000,7,NULL,NULL),(69,9,1,500.0000,1,NULL,NULL),(70,9,2,80.0000,2,NULL,NULL),(71,9,3,60.0000,3,NULL,NULL),(72,9,4,160.0000,4,NULL,NULL),(73,9,6,100.0000,5,NULL,NULL),(74,9,5,8.0000,6,NULL,NULL),(75,9,7,5.0000,7,NULL,NULL),(76,9,8,6.0000,8,NULL,NULL),(77,9,19,240.0000,9,NULL,NULL),(78,10,1,480.0000,1,NULL,NULL),(79,10,2,100.0000,2,NULL,NULL),(80,10,3,60.0000,3,NULL,NULL),(81,10,4,160.0000,4,NULL,NULL),(82,10,6,100.0000,5,NULL,NULL),(83,10,5,10.0000,6,NULL,NULL),(84,10,7,5.0000,7,NULL,NULL),(85,10,8,4.0000,8,NULL,NULL),(86,10,20,60.0000,9,NULL,NULL),(87,10,14,240.0000,10,NULL,NULL),(88,11,1,520.0000,1,NULL,NULL),(89,11,2,80.0000,2,NULL,NULL),(90,11,3,200.0000,3,NULL,NULL),(91,11,4,120.0000,4,NULL,NULL),(92,11,6,100.0000,5,NULL,NULL),(93,11,5,8.0000,6,NULL,NULL),(94,11,7,6.0000,7,NULL,NULL),(95,11,8,4.0000,8,NULL,NULL),(96,11,13,150.0000,9,NULL,NULL),(97,11,14,120.0000,10,NULL,NULL),(98,12,1,600.0000,1,NULL,NULL),(99,12,2,80.0000,2,NULL,NULL),(100,12,3,250.0000,3,NULL,NULL),(101,12,4,100.0000,4,NULL,NULL),(102,12,6,150.0000,5,NULL,NULL),(103,12,5,10.0000,6,NULL,NULL),(104,12,7,6.0000,7,NULL,NULL),(105,12,8,5.0000,8,NULL,NULL),(106,12,20,80.0000,9,NULL,NULL),(107,13,20,120.0000,1,NULL,NULL),(108,13,17,122.0000,2,NULL,NULL),(118,2,1,480.0000,1,NULL,NULL),(119,2,2,120.0000,2,NULL,NULL),(120,2,3,90.0000,3,NULL,NULL),(121,2,4,150.0000,4,NULL,NULL),(122,2,5,8.0000,5,NULL,NULL),(123,2,6,100.0000,6,NULL,NULL),(124,2,7,5.0000,7,NULL,NULL),(125,2,9,50.0000,8,NULL,NULL),(126,2,13,200.0000,9,NULL,NULL),(127,14,20,12.0000,1,NULL,NULL),(128,14,13,12.0000,2,NULL,NULL),(134,16,4,3000.0000,1,14,3.0000),(135,16,20,20.0000,2,76,2.0000),(136,17,1,167.0000,1,NULL,NULL),(137,17,2,40.0000,2,NULL,NULL),(138,17,3,27.0000,3,NULL,NULL),(139,17,4,50.0000,4,NULL,NULL),(140,17,6,33.0000,5,NULL,NULL),(141,17,5,3.0000,6,NULL,NULL),(142,17,7,2.0000,7,NULL,NULL),(143,17,8,2.0000,8,NULL,NULL),(144,17,13,80.0000,9,NULL,NULL),(145,17,21,1.0000,10,NULL,NULL),(146,18,1,333.0000,1,NULL,NULL),(147,18,2,80.0000,2,NULL,NULL),(148,18,3,53.0000,3,NULL,NULL),(149,18,4,100.0000,4,NULL,NULL),(150,18,6,67.0000,5,NULL,NULL),(151,18,5,5.0000,6,NULL,NULL),(152,18,7,3.0000,7,NULL,NULL),(153,18,8,3.0000,8,NULL,NULL),(154,18,13,160.0000,9,NULL,NULL),(155,18,22,1.0000,10,NULL,NULL),(156,19,1,500.0000,1,NULL,NULL),(157,19,2,120.0000,2,NULL,NULL),(158,19,3,80.0000,3,NULL,NULL),(159,19,4,150.0000,4,NULL,NULL),(160,19,6,100.0000,5,NULL,NULL),(161,19,5,8.0000,6,NULL,NULL),(162,19,7,5.0000,7,NULL,NULL),(163,19,8,5.0000,8,NULL,NULL),(164,19,13,240.0000,9,NULL,NULL),(165,19,23,1.0000,10,NULL,NULL),(166,20,1,160.0000,1,NULL,NULL),(167,20,2,40.0000,2,NULL,NULL),(168,20,3,30.0000,3,NULL,NULL),(169,20,4,50.0000,4,NULL,NULL),(170,20,5,3.0000,5,NULL,NULL),(171,20,6,33.0000,6,NULL,NULL),(172,20,7,2.0000,7,NULL,NULL),(173,20,9,17.0000,8,NULL,NULL),(174,20,13,67.0000,9,NULL,NULL),(175,20,21,1.0000,10,NULL,NULL),(176,21,1,320.0000,1,NULL,NULL),(177,21,2,80.0000,2,NULL,NULL),(178,21,3,60.0000,3,NULL,NULL),(179,21,4,100.0000,4,NULL,NULL),(180,21,5,5.0000,5,NULL,NULL),(181,21,6,67.0000,6,NULL,NULL),(182,21,7,3.0000,7,NULL,NULL),(183,21,9,33.0000,8,NULL,NULL),(184,21,13,133.0000,9,NULL,NULL),(185,21,22,1.0000,10,NULL,NULL),(186,22,1,480.0000,1,NULL,NULL),(187,22,2,120.0000,2,NULL,NULL),(188,22,3,90.0000,3,NULL,NULL),(189,22,4,150.0000,4,NULL,NULL),(190,22,5,8.0000,5,NULL,NULL),(191,22,6,100.0000,6,NULL,NULL),(192,22,7,5.0000,7,NULL,NULL),(193,22,9,50.0000,8,NULL,NULL),(194,22,13,200.0000,9,NULL,NULL),(195,22,23,1.0000,10,NULL,NULL),(196,23,1,183.0000,1,NULL,NULL),(197,23,2,27.0000,2,NULL,NULL),(198,23,3,67.0000,3,NULL,NULL),(199,23,4,40.0000,4,NULL,NULL),(200,23,6,33.0000,5,NULL,NULL),(201,23,5,3.0000,6,NULL,NULL),(202,23,7,2.0000,7,NULL,NULL),(203,23,12,70.0000,8,NULL,NULL),(204,23,11,70.0000,9,NULL,NULL),(205,23,21,1.0000,10,NULL,NULL),(206,24,1,367.0000,1,NULL,NULL),(207,24,2,53.0000,2,NULL,NULL),(208,24,3,133.0000,3,NULL,NULL),(209,24,4,80.0000,4,NULL,NULL),(210,24,6,67.0000,5,NULL,NULL),(211,24,5,5.0000,6,NULL,NULL),(212,24,7,4.0000,7,NULL,NULL),(213,24,12,140.0000,8,NULL,NULL),(214,24,11,140.0000,9,NULL,NULL),(215,24,22,1.0000,10,NULL,NULL),(216,25,1,550.0000,1,NULL,NULL),(217,25,2,80.0000,2,NULL,NULL),(218,25,3,200.0000,3,NULL,NULL),(219,25,4,120.0000,4,NULL,NULL),(220,25,6,100.0000,5,NULL,NULL),(221,25,5,8.0000,6,NULL,NULL),(222,25,7,6.0000,7,NULL,NULL),(223,25,12,210.0000,8,NULL,NULL),(224,25,11,210.0000,9,NULL,NULL),(225,25,23,1.0000,10,NULL,NULL),(226,26,1,150.0000,1,NULL,NULL),(227,26,2,33.0000,2,NULL,NULL),(228,26,3,20.0000,3,NULL,NULL),(229,26,4,53.0000,4,NULL,NULL),(230,26,6,33.0000,5,NULL,NULL),(231,26,5,3.0000,6,NULL,NULL),(232,26,7,2.0000,7,NULL,NULL),(233,26,9,10.0000,8,NULL,NULL),(234,26,15,83.0000,9,NULL,NULL),(235,26,21,1.0000,10,NULL,NULL),(236,27,1,300.0000,1,NULL,NULL),(237,27,2,67.0000,2,NULL,NULL),(238,27,3,40.0000,3,NULL,NULL),(239,27,4,107.0000,4,NULL,NULL),(240,27,6,67.0000,5,NULL,NULL),(241,27,5,5.0000,6,NULL,NULL),(242,27,7,3.0000,7,NULL,NULL),(243,27,9,20.0000,8,NULL,NULL),(244,27,15,167.0000,9,NULL,NULL),(245,27,22,1.0000,10,NULL,NULL),(246,28,1,450.0000,1,NULL,NULL),(247,28,2,100.0000,2,NULL,NULL),(248,28,3,60.0000,3,NULL,NULL),(249,28,4,160.0000,4,NULL,NULL),(250,28,6,100.0000,5,NULL,NULL),(251,28,5,8.0000,6,NULL,NULL),(252,28,7,5.0000,7,NULL,NULL),(253,28,9,30.0000,8,NULL,NULL),(254,28,15,250.0000,9,NULL,NULL),(255,28,23,1.0000,10,NULL,NULL),(256,29,1,183.0000,1,NULL,NULL),(257,29,2,23.0000,2,NULL,NULL),(258,29,3,67.0000,3,NULL,NULL),(259,29,4,40.0000,4,NULL,NULL),(260,29,6,33.0000,5,NULL,NULL),(261,29,5,3.0000,6,NULL,NULL),(262,29,7,2.0000,7,NULL,NULL),(263,29,16,93.0000,8,NULL,NULL),(264,29,21,1.0000,9,NULL,NULL),(265,30,1,367.0000,1,NULL,NULL),(266,30,2,47.0000,2,NULL,NULL),(267,30,3,133.0000,3,NULL,NULL),(268,30,4,80.0000,4,NULL,NULL),(269,30,6,67.0000,5,NULL,NULL),(270,30,5,5.0000,6,NULL,NULL),(271,30,7,4.0000,7,NULL,NULL),(272,30,16,187.0000,8,NULL,NULL),(273,30,22,1.0000,9,NULL,NULL),(274,31,1,550.0000,1,NULL,NULL),(275,31,2,70.0000,2,NULL,NULL),(276,31,3,200.0000,3,NULL,NULL),(277,31,4,120.0000,4,NULL,NULL),(278,31,6,100.0000,5,NULL,NULL),(279,31,5,8.0000,6,NULL,NULL),(280,31,7,6.0000,7,NULL,NULL),(281,31,16,280.0000,8,NULL,NULL),(282,31,23,1.0000,9,NULL,NULL),(283,32,1,133.0000,1,NULL,NULL),(284,32,2,27.0000,2,NULL,NULL),(285,32,3,60.0000,3,NULL,NULL),(286,32,6,20.0000,4,NULL,NULL),(287,32,7,1.0000,5,NULL,NULL),(288,32,8,1.0000,6,NULL,NULL),(289,32,20,17.0000,7,NULL,NULL),(290,32,17,67.0000,8,NULL,NULL),(291,32,21,1.0000,9,NULL,NULL),(292,33,1,267.0000,1,NULL,NULL),(293,33,2,53.0000,2,NULL,NULL),(294,33,3,120.0000,3,NULL,NULL),(295,33,6,40.0000,4,NULL,NULL),(296,33,7,2.0000,5,NULL,NULL),(297,33,8,3.0000,6,NULL,NULL),(298,33,20,33.0000,7,NULL,NULL),(299,33,17,133.0000,8,NULL,NULL),(300,33,22,1.0000,9,NULL,NULL),(301,34,1,400.0000,1,NULL,NULL),(302,34,2,80.0000,2,NULL,NULL),(303,34,3,180.0000,3,NULL,NULL),(304,34,6,60.0000,4,NULL,NULL),(305,34,7,3.0000,5,NULL,NULL),(306,34,8,4.0000,6,NULL,NULL),(307,34,20,50.0000,7,NULL,NULL),(308,34,17,200.0000,8,NULL,NULL),(309,34,23,1.0000,9,NULL,NULL),(310,35,1,167.0000,1,NULL,NULL),(311,35,2,20.0000,2,NULL,NULL),(312,35,3,27.0000,3,NULL,NULL),(313,35,4,60.0000,4,NULL,NULL),(314,35,6,27.0000,5,NULL,NULL),(315,35,5,3.0000,6,NULL,NULL),(316,35,7,2.0000,7,NULL,NULL),(317,35,10,5.0000,8,NULL,NULL),(318,35,18,67.0000,9,NULL,NULL),(319,35,21,1.0000,10,NULL,NULL),(320,36,1,333.0000,1,NULL,NULL),(321,36,2,40.0000,2,NULL,NULL),(322,36,3,53.0000,3,NULL,NULL),(323,36,4,120.0000,4,NULL,NULL),(324,36,6,53.0000,5,NULL,NULL),(325,36,5,7.0000,6,NULL,NULL),(326,36,7,4.0000,7,NULL,NULL),(327,36,10,10.0000,8,NULL,NULL),(328,36,18,133.0000,9,NULL,NULL),(329,36,22,1.0000,10,NULL,NULL),(330,37,1,500.0000,1,NULL,NULL),(331,37,2,60.0000,2,NULL,NULL),(332,37,3,80.0000,3,NULL,NULL),(333,37,4,180.0000,4,NULL,NULL),(334,37,6,80.0000,5,NULL,NULL),(335,37,5,10.0000,6,NULL,NULL),(336,37,7,6.0000,7,NULL,NULL),(337,37,10,15.0000,8,NULL,NULL),(338,37,18,200.0000,9,NULL,NULL),(339,37,23,1.0000,10,NULL,NULL),(340,38,1,100.0000,1,NULL,NULL),(341,38,9,27.0000,2,NULL,NULL),(342,38,2,40.0000,3,NULL,NULL),(343,38,3,50.0000,4,NULL,NULL),(344,38,6,67.0000,5,NULL,NULL),(345,38,7,1.0000,6,NULL,NULL),(346,38,13,50.0000,7,NULL,NULL),(347,38,21,1.0000,8,NULL,NULL),(348,39,1,200.0000,1,NULL,NULL),(349,39,9,53.0000,2,NULL,NULL),(350,39,2,80.0000,3,NULL,NULL),(351,39,3,100.0000,4,NULL,NULL),(352,39,6,133.0000,5,NULL,NULL),(353,39,7,2.0000,6,NULL,NULL),(354,39,13,100.0000,7,NULL,NULL),(355,39,22,1.0000,8,NULL,NULL),(356,40,1,300.0000,1,NULL,NULL),(357,40,9,80.0000,2,NULL,NULL),(358,40,2,120.0000,3,NULL,NULL),(359,40,3,150.0000,4,NULL,NULL),(360,40,6,200.0000,5,NULL,NULL),(361,40,7,3.0000,6,NULL,NULL),(362,40,13,150.0000,7,NULL,NULL),(363,40,23,1.0000,8,NULL,NULL),(364,41,1,167.0000,1,NULL,NULL),(365,41,2,27.0000,2,NULL,NULL),(366,41,3,20.0000,3,NULL,NULL),(367,41,4,53.0000,4,NULL,NULL),(368,41,6,33.0000,5,NULL,NULL),(369,41,5,3.0000,6,NULL,NULL),(370,41,7,2.0000,7,NULL,NULL),(371,41,8,2.0000,8,NULL,NULL),(372,41,19,80.0000,9,NULL,NULL),(373,41,21,1.0000,10,NULL,NULL),(374,42,1,333.0000,1,NULL,NULL),(375,42,2,53.0000,2,NULL,NULL),(376,42,3,40.0000,3,NULL,NULL),(377,42,4,107.0000,4,NULL,NULL),(378,42,6,67.0000,5,NULL,NULL),(379,42,5,5.0000,6,NULL,NULL),(380,42,7,3.0000,7,NULL,NULL),(381,42,8,4.0000,8,NULL,NULL),(382,42,19,160.0000,9,NULL,NULL),(383,42,22,1.0000,10,NULL,NULL),(384,43,1,500.0000,1,NULL,NULL),(385,43,2,80.0000,2,NULL,NULL),(386,43,3,60.0000,3,NULL,NULL),(387,43,4,160.0000,4,NULL,NULL),(388,43,6,100.0000,5,NULL,NULL),(389,43,5,8.0000,6,NULL,NULL),(390,43,7,5.0000,7,NULL,NULL),(391,43,8,6.0000,8,NULL,NULL),(392,43,19,240.0000,9,NULL,NULL),(393,43,23,1.0000,10,NULL,NULL),(394,44,1,160.0000,1,NULL,NULL),(395,44,2,33.0000,2,NULL,NULL),(396,44,3,20.0000,3,NULL,NULL),(397,44,4,53.0000,4,NULL,NULL),(398,44,6,33.0000,5,NULL,NULL),(399,44,5,3.0000,6,NULL,NULL),(400,44,7,2.0000,7,NULL,NULL),(401,44,8,1.0000,8,NULL,NULL),(402,44,20,20.0000,9,NULL,NULL),(403,44,14,80.0000,10,NULL,NULL),(404,44,21,1.0000,11,NULL,NULL),(405,45,1,320.0000,1,NULL,NULL),(406,45,2,67.0000,2,NULL,NULL),(407,45,3,40.0000,3,NULL,NULL),(408,45,4,107.0000,4,NULL,NULL),(409,45,6,67.0000,5,NULL,NULL),(410,45,5,7.0000,6,NULL,NULL),(411,45,7,3.0000,7,NULL,NULL),(412,45,8,3.0000,8,NULL,NULL),(413,45,20,40.0000,9,NULL,NULL),(414,45,14,160.0000,10,NULL,NULL),(415,45,22,1.0000,11,NULL,NULL),(416,46,1,480.0000,1,NULL,NULL),(417,46,2,100.0000,2,NULL,NULL),(418,46,3,60.0000,3,NULL,NULL),(419,46,4,160.0000,4,NULL,NULL),(420,46,6,100.0000,5,NULL,NULL),(421,46,5,10.0000,6,NULL,NULL),(422,46,7,5.0000,7,NULL,NULL),(423,46,8,4.0000,8,NULL,NULL),(424,46,20,60.0000,9,NULL,NULL),(425,46,14,240.0000,10,NULL,NULL),(426,46,23,1.0000,11,NULL,NULL),(427,47,1,173.0000,1,NULL,NULL),(428,47,2,27.0000,2,NULL,NULL),(429,47,3,67.0000,3,NULL,NULL),(430,47,4,40.0000,4,NULL,NULL),(431,47,6,33.0000,5,NULL,NULL),(432,47,5,3.0000,6,NULL,NULL),(433,47,7,2.0000,7,NULL,NULL),(434,47,8,1.0000,8,NULL,NULL),(435,47,13,50.0000,9,NULL,NULL),(436,47,14,40.0000,10,NULL,NULL),(437,47,21,1.0000,11,NULL,NULL),(438,48,1,347.0000,1,NULL,NULL),(439,48,2,53.0000,2,NULL,NULL),(440,48,3,133.0000,3,NULL,NULL),(441,48,4,80.0000,4,NULL,NULL),(442,48,6,67.0000,5,NULL,NULL),(443,48,5,5.0000,6,NULL,NULL),(444,48,7,4.0000,7,NULL,NULL),(445,48,8,3.0000,8,NULL,NULL),(446,48,13,100.0000,9,NULL,NULL),(447,48,14,80.0000,10,NULL,NULL),(448,48,22,1.0000,11,NULL,NULL),(449,49,1,520.0000,1,NULL,NULL),(450,49,2,80.0000,2,NULL,NULL),(451,49,3,200.0000,3,NULL,NULL),(452,49,4,120.0000,4,NULL,NULL),(453,49,6,100.0000,5,NULL,NULL),(454,49,5,8.0000,6,NULL,NULL),(455,49,7,6.0000,7,NULL,NULL),(456,49,8,4.0000,8,NULL,NULL),(457,49,13,150.0000,9,NULL,NULL),(458,49,14,120.0000,10,NULL,NULL),(459,49,23,1.0000,11,NULL,NULL),(460,50,1,200.0000,1,NULL,NULL),(461,50,2,27.0000,2,NULL,NULL),(462,50,3,83.0000,3,NULL,NULL),(463,50,4,33.0000,4,NULL,NULL),(464,50,6,50.0000,5,NULL,NULL),(465,50,5,3.0000,6,NULL,NULL),(466,50,7,2.0000,7,NULL,NULL),(467,50,8,2.0000,8,NULL,NULL),(468,50,20,27.0000,9,NULL,NULL),(469,50,21,1.0000,10,NULL,NULL),(470,51,1,400.0000,1,NULL,NULL),(471,51,2,53.0000,2,NULL,NULL),(472,51,3,167.0000,3,NULL,NULL),(473,51,4,67.0000,4,NULL,NULL),(474,51,6,100.0000,5,NULL,NULL),(475,51,5,7.0000,6,NULL,NULL),(476,51,7,4.0000,7,NULL,NULL),(477,51,8,3.0000,8,NULL,NULL),(478,51,20,53.0000,9,NULL,NULL),(479,51,22,1.0000,10,NULL,NULL),(480,52,1,600.0000,1,NULL,NULL),(481,52,2,80.0000,2,NULL,NULL),(482,52,3,250.0000,3,NULL,NULL),(483,52,4,100.0000,4,NULL,NULL),(484,52,6,150.0000,5,NULL,NULL),(485,52,5,10.0000,6,NULL,NULL),(486,52,7,6.0000,7,NULL,NULL),(487,52,8,5.0000,8,NULL,NULL),(488,52,20,80.0000,9,NULL,NULL),(489,52,23,1.0000,10,NULL,NULL);
/*!40000 ALTER TABLE `detalle_recetas` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `detalle_ventas`
--

DROP TABLE IF EXISTS `detalle_ventas`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `detalle_ventas` (
  `id_detalle_venta` int NOT NULL AUTO_INCREMENT,
  `id_venta` int NOT NULL,
  `id_producto` int DEFAULT NULL COMMENT 'Producto suelto vendido. NULL cuando la venta es una caja.',
  `cantidad` decimal(10,2) NOT NULL,
  `precio_unitario` decimal(10,2) NOT NULL,
  `descuento_pct` decimal(5,2) NOT NULL,
  `subtotal` decimal(12,2) NOT NULL,
  `id_caja` int DEFAULT NULL COMMENT 'Caja vendida. NULL = venta de pieza suelta.',
  PRIMARY KEY (`id_detalle_venta`),
  KEY `id_venta` (`id_venta`),
  KEY `fk_detventa_producto` (`id_producto`),
  KEY `fk_detventa_caja` (`id_caja`),
  CONSTRAINT `detalle_ventas_ibfk_2` FOREIGN KEY (`id_venta`) REFERENCES `ventas` (`id_venta`) ON DELETE CASCADE,
  CONSTRAINT `fk_detventa_caja` FOREIGN KEY (`id_caja`) REFERENCES `cajas` (`id_caja`) ON DELETE SET NULL,
  CONSTRAINT `fk_detventa_producto` FOREIGN KEY (`id_producto`) REFERENCES `productos` (`id_producto`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `detalle_ventas`
--

LOCK TABLES `detalle_ventas` WRITE;
/*!40000 ALTER TABLE `detalle_ventas` DISABLE KEYS */;
/*!40000 ALTER TABLE `detalle_ventas` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `historial_pedidos`
--

DROP TABLE IF EXISTS `historial_pedidos`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `historial_pedidos` (
  `id_historial` int NOT NULL AUTO_INCREMENT,
  `id_pedido` int NOT NULL,
  `estado_antes` varchar(20) COLLATE utf8mb4_unicode_ci NOT NULL,
  `estado_despues` varchar(20) COLLATE utf8mb4_unicode_ci NOT NULL,
  `nota` text COLLATE utf8mb4_unicode_ci,
  `realizado_por` int DEFAULT NULL,
  `creado_en` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id_historial`),
  KEY `fk_hist_pedido` (`id_pedido`),
  KEY `fk_hist_usuario` (`realizado_por`),
  KEY `idx_hist_pedido_fecha` (`id_pedido`,`creado_en`),
  CONSTRAINT `fk_hist_pedido` FOREIGN KEY (`id_pedido`) REFERENCES `pedidos` (`id_pedido`) ON DELETE CASCADE,
  CONSTRAINT `fk_hist_usuario` FOREIGN KEY (`realizado_por`) REFERENCES `usuarios` (`id_usuario`) ON DELETE SET NULL
) ENGINE=InnoDB AUTO_INCREMENT=5 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Auditoría de cada cambio de estado en un pedido';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `historial_pedidos`
--

LOCK TABLES `historial_pedidos` WRITE;
/*!40000 ALTER TABLE `historial_pedidos` DISABLE KEYS */;
INSERT INTO `historial_pedidos` VALUES (1,1,'nuevo','pendiente','Pedido creado por el cliente',3,'2026-03-26 12:19:01'),(2,2,'nuevo','pendiente','Pedido creado por el cliente',3,'2026-03-26 12:50:55'),(3,3,'nuevo','pendiente','Pedido de caja creado por el cliente.',3,'2026-03-26 15:08:41'),(4,4,'nuevo','pendiente','Pedido de caja creado por el cliente.',3,'2026-03-26 15:33:31');
/*!40000 ALTER TABLE `historial_pedidos` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `inventario_pt`
--

DROP TABLE IF EXISTS `inventario_pt`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `inventario_pt` (
  `id_inventario` int NOT NULL AUTO_INCREMENT,
  `id_producto` int NOT NULL,
  `stock_actual` decimal(12,2) NOT NULL DEFAULT '0.00',
  `stock_minimo` decimal(12,2) NOT NULL DEFAULT '0.00',
  `ultima_actualizacion` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id_inventario`),
  UNIQUE KEY `uq_inv_producto` (`id_producto`),
  CONSTRAINT `fk_inv_producto` FOREIGN KEY (`id_producto`) REFERENCES `productos` (`id_producto`) ON DELETE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=13 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Stock en tiempo real de cada producto terminado.';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `inventario_pt`
--

LOCK TABLES `inventario_pt` WRITE;
/*!40000 ALTER TABLE `inventario_pt` DISABLE KEYS */;
INSERT INTO `inventario_pt` VALUES (1,1,0.00,20.00,'2026-03-24 14:42:13'),(2,2,0.00,20.00,'2026-03-24 14:42:13'),(3,3,0.00,20.00,'2026-03-24 14:42:13'),(4,4,0.00,15.00,'2026-03-24 14:42:13'),(5,5,0.00,20.00,'2026-03-24 14:42:13'),(6,6,0.00,15.00,'2026-03-24 14:42:13'),(7,7,0.00,15.00,'2026-03-24 14:42:13'),(8,8,0.00,15.00,'2026-03-24 14:42:13'),(9,9,0.00,20.00,'2026-03-24 14:42:13'),(10,10,0.00,20.00,'2026-03-24 14:42:13'),(11,11,0.00,15.00,'2026-03-24 14:42:13'),(12,12,0.00,25.00,'2026-03-24 14:42:13');
/*!40000 ALTER TABLE `inventario_pt` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `logs_sistema`
--

DROP TABLE IF EXISTS `logs_sistema`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `logs_sistema` (
  `id_log` bigint NOT NULL AUTO_INCREMENT,
  `tipo` enum('error','acceso','cambio_usuario','venta','compra','produccion','ajuste_inv','solicitud','salida_efectivo','seguridad') NOT NULL,
  `nivel` enum('INFO','WARNING','ERROR','CRITICAL') NOT NULL,
  `id_usuario` int DEFAULT NULL,
  `modulo` varchar(60) DEFAULT NULL,
  `accion` varchar(120) DEFAULT NULL,
  `descripcion` text,
  `ip_origen` varchar(45) DEFAULT NULL,
  `user_agent` varchar(255) DEFAULT NULL,
  `referencia_id` int DEFAULT NULL,
  `referencia_tipo` varchar(60) DEFAULT NULL,
  `creado_en` datetime NOT NULL,
  PRIMARY KEY (`id_log`),
  KEY `id_usuario` (`id_usuario`),
  CONSTRAINT `logs_sistema_ibfk_1` FOREIGN KEY (`id_usuario`) REFERENCES `usuarios` (`id_usuario`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `logs_sistema`
--

LOCK TABLES `logs_sistema` WRITE;
/*!40000 ALTER TABLE `logs_sistema` DISABLE KEYS */;
/*!40000 ALTER TABLE `logs_sistema` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `materias_primas`
--

DROP TABLE IF EXISTS `materias_primas`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `materias_primas` (
  `id_materia` int NOT NULL AUTO_INCREMENT,
  `uuid_materia` varchar(36) NOT NULL,
  `nombre` varchar(120) NOT NULL,
  `categoria` varchar(60) DEFAULT NULL,
  `unidad_base` varchar(20) NOT NULL,
  `stock_actual` decimal(12,4) NOT NULL,
  `stock_minimo` decimal(12,4) NOT NULL,
  `estatus` enum('activo','inactivo') NOT NULL,
  `creado_en` datetime NOT NULL,
  `actualizado_en` datetime NOT NULL,
  `creado_por` int DEFAULT NULL,
  PRIMARY KEY (`id_materia`),
  UNIQUE KEY `uuid_materia` (`uuid_materia`),
  KEY `creado_por` (`creado_por`),
  CONSTRAINT `materias_primas_ibfk_1` FOREIGN KEY (`creado_por`) REFERENCES `usuarios` (`id_usuario`)
) ENGINE=InnoDB AUTO_INCREMENT=24 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `materias_primas`
--

LOCK TABLES `materias_primas` WRITE;
/*!40000 ALTER TABLE `materias_primas` DISABLE KEYS */;
INSERT INTO `materias_primas` VALUES (1,'84bb422b-2613-11f1-9474-c01850d072b8','Harina de Trigo','Harinas','g',39000.0000,5000.0000,'activo','2026-03-22 11:21:09','2026-03-24 21:20:17',1),(2,'84bd05a6-2613-11f1-9474-c01850d072b8','Azúcar Refinada','Endulzantes','g',7760.0000,2000.0000,'activo','2026-03-22 11:21:09','2026-03-24 21:20:17',1),(3,'84bd0bd2-2613-11f1-9474-c01850d072b8','Mantequilla','Grasas','g',5840.0000,2000.0000,'activo','2026-03-22 11:21:09','2026-03-24 21:20:17',1),(4,'84bd0f0a-2613-11f1-9474-c01850d072b8','Leche Entera','Lácteos','ml',4700.0000,1000.0000,'activo','2026-03-22 11:21:09','2026-03-24 21:20:17',1),(5,'84bd1c40-2613-11f1-9474-c01850d072b8','Levadura Seca','Fermentación','g',484.0000,100.0000,'activo','2026-03-22 11:21:09','2026-03-24 21:20:17',1),(6,'84bd1fe6-2613-11f1-9474-c01850d072b8','Huevo','Proteínas','g',2800.0000,600.0000,'activo','2026-03-22 11:21:09','2026-03-24 21:20:17',1),(7,'84bd2126-2613-11f1-9474-c01850d072b8','Sal','Condimentos','g',1990.0000,200.0000,'activo','2026-03-22 11:21:09','2026-03-24 21:20:17',1),(8,'84bd22ba-2613-11f1-9474-c01850d072b8','Esencia de Vainilla','Saborizantes','ml',290.0000,50.0000,'activo','2026-03-22 11:21:09','2026-03-24 21:20:17',1),(9,'84bd23ed-2613-11f1-9474-c01850d072b8','Cocoa en Polvo','Saborizantes','g',1500.0000,300.0000,'activo','2026-03-22 11:21:09','2026-03-22 11:21:09',1),(10,'84bd24f6-2613-11f1-9474-c01850d072b8','Canela Molida','Especias','g',500.0000,100.0000,'activo','2026-03-22 11:21:09','2026-03-22 11:21:09',1),(11,'84bd2613-2613-11f1-9474-c01850d072b8','Queso Crema','Lácteos','g',2000.0000,500.0000,'activo','2026-03-22 11:21:09','2026-03-22 11:21:09',1),(12,'84bd5a67-2613-11f1-9474-c01850d072b8','Cajeta','Rellenos','g',1500.0000,300.0000,'activo','2026-03-22 11:21:09','2026-03-22 11:21:09',1),(13,'84bd64c5-2613-11f1-9474-c01850d072b8','Crema Pastelera','Rellenos','g',2520.0000,500.0000,'activo','2026-03-22 11:21:09','2026-03-24 21:20:17',1),(14,'84bd6626-2613-11f1-9474-c01850d072b8','Mermelada de Fresa','Rellenos','g',2000.0000,400.0000,'activo','2026-03-22 11:21:09','2026-03-22 11:21:09',1),(15,'84bd6799-2613-11f1-9474-c01850d072b8','Crema de Avellana','Rellenos','g',1500.0000,300.0000,'activo','2026-03-22 11:21:09','2026-03-22 11:21:09',1),(16,'84bd694b-2613-11f1-9474-c01850d072b8','Dulce de Leche','Rellenos','g',1800.0000,300.0000,'activo','2026-03-22 11:21:09','2026-03-22 11:21:09',1),(17,'84bd6a5b-2613-11f1-9474-c01850d072b8','Crema de Limón','Rellenos','g',1000.0000,200.0000,'activo','2026-03-22 11:21:09','2026-03-22 11:21:09',1),(18,'84bd6b7d-2613-11f1-9474-c01850d072b8','Piloncillo','Endulzantes','g',2000.0000,400.0000,'activo','2026-03-22 11:21:09','2026-03-22 11:21:09',1),(19,'84bd6c9b-2613-11f1-9474-c01850d072b8','Requesón','Lácteos','g',1200.0000,300.0000,'activo','2026-03-22 11:21:09','2026-03-22 11:21:09',1),(20,'84bd6dbd-2613-11f1-9474-c01850d072b8','Azúcar Glass','Endulzantes','g',2000.0000,300.0000,'activo','2026-03-22 11:21:09','2026-03-22 11:21:09',1),(21,'474e27bc-2959-11f1-828b-c01850d072b8','Caja de Cartón Chica','Empaque','pza',50.0000,10.0000,'activo','2026-03-26 15:18:05','2026-03-26 15:18:05',1),(22,'4751491a-2959-11f1-828b-c01850d072b8','Caja de Cartón Mediana','Empaque','pza',50.0000,10.0000,'activo','2026-03-26 15:18:05','2026-03-26 15:18:05',1),(23,'47514b46-2959-11f1-828b-c01850d072b8','Caja de Cartón Grande','Empaque','pza',50.0000,10.0000,'activo','2026-03-26 15:18:05','2026-03-26 15:18:05',1);
/*!40000 ALTER TABLE `materias_primas` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `mermas`
--

DROP TABLE IF EXISTS `mermas`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `mermas` (
  `id_merma` int NOT NULL AUTO_INCREMENT,
  `tipo_objeto` enum('materia_prima','producto_terminado','lote_produccion') NOT NULL,
  `id_referencia` int NOT NULL,
  `cantidad` decimal(12,4) NOT NULL,
  `unidad` varchar(20) NOT NULL,
  `causa` enum('caducidad','quemado_horneado','caida_accidente','error_produccion','rotura_empaque','contaminacion','otro') NOT NULL,
  `descripcion` text,
  `id_produccion` int DEFAULT NULL,
  `registrado_por` int NOT NULL,
  `fecha_merma` datetime NOT NULL,
  `creado_en` datetime NOT NULL,
  PRIMARY KEY (`id_merma`),
  KEY `id_produccion` (`id_produccion`),
  KEY `registrado_por` (`registrado_por`),
  CONSTRAINT `mermas_ibfk_1` FOREIGN KEY (`id_produccion`) REFERENCES `produccion` (`id_produccion`) ON DELETE SET NULL,
  CONSTRAINT `mermas_ibfk_2` FOREIGN KEY (`registrado_por`) REFERENCES `usuarios` (`id_usuario`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `mermas`
--

LOCK TABLES `mermas` WRITE;
/*!40000 ALTER TABLE `mermas` DISABLE KEYS */;
/*!40000 ALTER TABLE `mermas` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `notificaciones_pedidos`
--

DROP TABLE IF EXISTS `notificaciones_pedidos`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `notificaciones_pedidos` (
  `id_notif` int NOT NULL AUTO_INCREMENT,
  `id_pedido` int NOT NULL,
  `id_usuario` int NOT NULL COMMENT 'Destinatario',
  `folio` varchar(15) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `tipo` enum('aprobado','rechazado','listo','entregado') COLLATE utf8mb4_unicode_ci NOT NULL,
  `mensaje` text COLLATE utf8mb4_unicode_ci NOT NULL,
  `leida` tinyint(1) NOT NULL DEFAULT '0',
  `creado_en` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id_notif`),
  KEY `fk_notif_pedido` (`id_pedido`),
  KEY `fk_notif_usuario` (`id_usuario`),
  KEY `idx_notif_usuario_leida` (`id_usuario`,`leida`),
  KEY `idx_notif_folio` (`folio`),
  CONSTRAINT `fk_notif_pedido` FOREIGN KEY (`id_pedido`) REFERENCES `pedidos` (`id_pedido`) ON DELETE CASCADE,
  CONSTRAINT `fk_notif_usuario` FOREIGN KEY (`id_usuario`) REFERENCES `usuarios` (`id_usuario`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Notificaciones de estado al cliente';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `notificaciones_pedidos`
--

LOCK TABLES `notificaciones_pedidos` WRITE;
/*!40000 ALTER TABLE `notificaciones_pedidos` DISABLE KEYS */;
/*!40000 ALTER TABLE `notificaciones_pedidos` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `pedido_productos`
--

DROP TABLE IF EXISTS `pedido_productos`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `pedido_productos` (
  `id_pedido_producto` int NOT NULL AUTO_INCREMENT,
  `id_pedido` int NOT NULL,
  `id_producto` int NOT NULL,
  `cantidad` tinyint NOT NULL,
  `precio_unitario` decimal(10,2) NOT NULL,
  PRIMARY KEY (`id_pedido_producto`),
  KEY `fk_pp_pedido` (`id_pedido`),
  KEY `fk_pp_producto` (`id_producto`),
  CONSTRAINT `fk_pp_pedido` FOREIGN KEY (`id_pedido`) REFERENCES `pedidos` (`id_pedido`) ON DELETE CASCADE,
  CONSTRAINT `fk_pp_producto` FOREIGN KEY (`id_producto`) REFERENCES `productos` (`id_producto`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci COMMENT='Panes individuales que componen cada pedido de caja.';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `pedido_productos`
--

LOCK TABLES `pedido_productos` WRITE;
/*!40000 ALTER TABLE `pedido_productos` DISABLE KEYS */;
/*!40000 ALTER TABLE `pedido_productos` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `pedidos`
--

DROP TABLE IF EXISTS `pedidos`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `pedidos` (
  `id_pedido` int NOT NULL AUTO_INCREMENT,
  `uuid_pedido` varchar(36) COLLATE utf8mb4_unicode_ci NOT NULL,
  `folio` varchar(15) COLLATE utf8mb4_unicode_ci NOT NULL COMMENT 'PED-0001',
  `id_cliente` int NOT NULL COMMENT 'FK a usuarios con rol cliente',
  `id_tamanio` int DEFAULT NULL COMMENT 'FK a tamanios_charola',
  `tipo` enum('simple','mixta','triple') COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'simple' COMMENT 'Tipo de caja pedida',
  `estado` enum('pendiente','aprobado','en_produccion','listo','entregado','rechazado') COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'pendiente',
  `fecha_recogida` datetime NOT NULL COMMENT 'Cuándo quiere recoger el cliente',
  `notas_cliente` text COLLATE utf8mb4_unicode_ci COMMENT 'Indicaciones especiales del cliente',
  `motivo_rechazo` text COLLATE utf8mb4_unicode_ci COMMENT 'Razón del rechazo, visible al cliente',
  `total_estimado` decimal(10,2) NOT NULL DEFAULT '0.00',
  `atendido_por` int DEFAULT NULL COMMENT 'Usuario que aprobó/rechazó',
  `creado_en` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `actualizado_en` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id_pedido`),
  UNIQUE KEY `uq_uuid_pedido` (`uuid_pedido`),
  UNIQUE KEY `uq_folio_pedido` (`folio`),
  KEY `fk_pedido_atiende` (`atendido_por`),
  KEY `idx_pedidos_estado` (`estado`),
  KEY `idx_pedidos_estado_fecha` (`estado`,`fecha_recogida`),
  KEY `idx_pedidos_cliente_estado` (`id_cliente`,`estado`),
  KEY `idx_pedidos_tamanio` (`id_tamanio`),
  KEY `idx_pedidos_folio` (`folio`),
  KEY `idx_pedidos_fecha_recogida` (`fecha_recogida`),
  CONSTRAINT `fk_pedido_atiende` FOREIGN KEY (`atendido_por`) REFERENCES `usuarios` (`id_usuario`) ON DELETE SET NULL,
  CONSTRAINT `fk_pedido_cliente` FOREIGN KEY (`id_cliente`) REFERENCES `usuarios` (`id_usuario`) ON DELETE RESTRICT,
  CONSTRAINT `fk_pedido_tamanio` FOREIGN KEY (`id_tamanio`) REFERENCES `tamanios_charola` (`id_tamanio`) ON DELETE SET NULL
) ENGINE=InnoDB AUTO_INCREMENT=5 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Cabecera de pedidos realizados por clientes web';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `pedidos`
--

LOCK TABLES `pedidos` WRITE;
/*!40000 ALTER TABLE `pedidos` DISABLE KEYS */;
INSERT INTO `pedidos` VALUES (1,'438ee468-2940-11f1-828b-c01850d072b8','PED-0001',3,NULL,'simple','pendiente','2026-03-27 18:41:00','ninguna',NULL,212.00,NULL,'2026-03-26 12:19:01','2026-03-26 12:19:01'),(2,'b84176de-2944-11f1-828b-c01850d072b8','PED-0002',3,NULL,'simple','pendiente','2026-03-28 14:55:00',NULL,NULL,198.00,NULL,'2026-03-26 12:50:55','2026-03-26 12:50:55'),(3,'f7a484e9-2957-11f1-828b-c01850d072b8','PED-0003',3,1,'simple','pendiente','2026-03-26 16:15:00',NULL,NULL,80.00,NULL,'2026-03-26 15:08:41','2026-03-26 15:08:41'),(4,'6fa4961b-295b-11f1-828b-c01850d072b8','PED-0004',3,3,'triple','pendiente','2026-03-26 17:45:00',NULL,NULL,304.00,NULL,'2026-03-26 15:33:31','2026-03-26 15:33:31');
/*!40000 ALTER TABLE `pedidos` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `produccion`
--

DROP TABLE IF EXISTS `produccion`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `produccion` (
  `id_produccion` int NOT NULL AUTO_INCREMENT,
  `folio_lote` varchar(20) NOT NULL,
  `id_producto` int NOT NULL,
  `id_receta` int NOT NULL,
  `cantidad_lotes` decimal(10,2) NOT NULL,
  `piezas_esperadas` decimal(10,2) NOT NULL,
  `piezas_producidas` decimal(10,2) DEFAULT NULL,
  `estado` enum('pendiente','en_proceso','finalizado','cancelado') NOT NULL,
  `fecha_inicio` datetime DEFAULT NULL,
  `fecha_fin_estimado` datetime DEFAULT NULL,
  `fecha_fin_real` datetime DEFAULT NULL,
  `operario_id` int DEFAULT NULL,
  `observaciones` text,
  `creado_en` datetime NOT NULL,
  `creado_por` int DEFAULT NULL,
  PRIMARY KEY (`id_produccion`),
  UNIQUE KEY `folio_lote` (`folio_lote`),
  KEY `creado_por` (`creado_por`),
  KEY `id_receta` (`id_receta`),
  KEY `operario_id` (`operario_id`),
  KEY `fk_produccion_producto` (`id_producto`),
  CONSTRAINT `fk_produccion_producto` FOREIGN KEY (`id_producto`) REFERENCES `productos` (`id_producto`),
  CONSTRAINT `produccion_ibfk_1` FOREIGN KEY (`creado_por`) REFERENCES `usuarios` (`id_usuario`) ON DELETE SET NULL,
  CONSTRAINT `produccion_ibfk_3` FOREIGN KEY (`id_receta`) REFERENCES `recetas` (`id_receta`),
  CONSTRAINT `produccion_ibfk_4` FOREIGN KEY (`operario_id`) REFERENCES `usuarios` (`id_usuario`) ON DELETE SET NULL
) ENGINE=InnoDB AUTO_INCREMENT=6 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `produccion`
--

LOCK TABLES `produccion` WRITE;
/*!40000 ALTER TABLE `produccion` DISABLE KEYS */;
INSERT INTO `produccion` VALUES (5,'L-0025',1,1,2.00,24.00,NULL,'pendiente','2026-03-24 21:20:17','2026-03-24 23:20:17',NULL,1,'Lote matutino','2026-03-24 21:20:17',1);
/*!40000 ALTER TABLE `produccion` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `productos`
--

DROP TABLE IF EXISTS `productos`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `productos` (
  `id_producto` int NOT NULL AUTO_INCREMENT,
  `uuid_producto` varchar(36) COLLATE utf8mb4_unicode_ci NOT NULL,
  `nombre` varchar(120) COLLATE utf8mb4_unicode_ci NOT NULL,
  `descripcion` text COLLATE utf8mb4_unicode_ci,
  `precio_venta` decimal(10,2) NOT NULL DEFAULT '0.00',
  `estatus` enum('activo','inactivo') COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'activo',
  `creado_en` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `actualizado_en` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `creado_por` int DEFAULT NULL,
  PRIMARY KEY (`id_producto`),
  UNIQUE KEY `uq_uuid_producto` (`uuid_producto`),
  KEY `fk_prod_creado_por` (`creado_por`),
  CONSTRAINT `fk_prod_creado_por` FOREIGN KEY (`creado_por`) REFERENCES `usuarios` (`id_usuario`) ON DELETE SET NULL
) ENGINE=InnoDB AUTO_INCREMENT=13 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Catálogo de productos terminados (datos estáticos).';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `productos`
--

LOCK TABLES `productos` WRITE;
/*!40000 ALTER TABLE `productos` DISABLE KEYS */;
INSERT INTO `productos` VALUES (1,'84e8ac4f-2613-11f1-9474-c01850d072b8','Concha de Crema Pastelera','Concha suave rellena de crema pastelera clásica',24.00,'activo','2026-03-22 11:21:10','2026-03-22 11:21:10',NULL),(2,'84e8d2df-2613-11f1-9474-c01850d072b8','Concha de Chocolate','Concha de cocoa rellena de crema de chocolate',26.00,'activo','2026-03-22 11:21:10','2026-03-22 11:21:10',NULL),(3,'84e8d5db-2613-11f1-9474-c01850d072b8','Cuernito de Cajeta y Queso','Cuernito hojaldrado relleno de cajeta y queso crema',26.00,'activo','2026-03-22 11:21:10','2026-03-22 11:21:10',NULL),(4,'84e8d72f-2613-11f1-9474-c01850d072b8','Dona de Crema de Avellana','Dona con glaseado de chocolate rellena de crema de avellana',28.00,'activo','2026-03-22 11:21:10','2026-03-22 11:21:10',NULL),(5,'84e8d842-2613-11f1-9474-c01850d072b8','Cuernito de Dulce de Leche','Cuernito hojaldrado relleno de dulce de leche',25.00,'activo','2026-03-22 11:21:10','2026-03-22 11:21:10',NULL),(6,'84e8d976-2613-11f1-9474-c01850d072b8','Polvorón de Crema de Limón','Polvorón de mantequilla relleno de crema de limón',26.00,'activo','2026-03-22 11:21:10','2026-03-24 16:26:10',NULL),(7,'84e8da8e-2613-11f1-9474-c01850d072b8','Trenza de Canela y Piloncillo','Trenza de masa dulce rellena de piloncillo y canela',24.00,'activo','2026-03-22 11:21:10','2026-03-22 11:21:10',NULL),(8,'84e8dbb3-2613-11f1-9474-c01850d072b8','Volcán de Chocolate','Pan individual de cocoa con centro de crema de chocolate',30.00,'activo','2026-03-22 11:21:10','2026-03-22 11:21:10',NULL),(9,'84e8dd04-2613-11f1-9474-c01850d072b8','Mogote de Requesón y Vainilla','Pan redondo esponjoso relleno de requesón con vainilla',24.00,'activo','2026-03-22 11:21:10','2026-03-22 11:21:10',NULL),(10,'84e8de28-2613-11f1-9474-c01850d072b8','Dona de Mermelada de Fresa','Dona con azúcar glass rellena de mermelada de fresa',22.00,'activo','2026-03-22 11:21:10','2026-03-22 11:21:10',NULL),(11,'84e8df44-2613-11f1-9474-c01850d072b8','Cuernito de Crema Pastelera y Fresa','Cuernito hojaldrado con doble relleno de crema pastelera y fresa',28.00,'activo','2026-03-22 11:21:10','2026-03-22 11:21:10',NULL),(12,'84e8e05d-2613-11f1-9474-c01850d072b8','Brioche de Mantequilla y Azúcar Glass','Pan brioche relleno de mantequilla y cubierto de azúcar glass',20.00,'activo','2026-03-22 11:21:10','2026-03-25 17:48:17',NULL);
/*!40000 ALTER TABLE `productos` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `productos_terminados`
--

DROP TABLE IF EXISTS `productos_terminados`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `productos_terminados` (
  `id_producto` int NOT NULL AUTO_INCREMENT,
  `uuid_producto` varchar(36) NOT NULL,
  `nombre` varchar(120) NOT NULL,
  `descripcion` text,
  `precio_venta` decimal(10,2) NOT NULL,
  `stock_actual` decimal(12,2) NOT NULL,
  `stock_minimo` decimal(12,2) NOT NULL,
  `estatus` enum('activo','inactivo') NOT NULL,
  `creado_en` datetime NOT NULL,
  `actualizado_en` datetime NOT NULL,
  PRIMARY KEY (`id_producto`),
  UNIQUE KEY `uuid_producto` (`uuid_producto`)
) ENGINE=InnoDB AUTO_INCREMENT=13 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `productos_terminados`
--

LOCK TABLES `productos_terminados` WRITE;
/*!40000 ALTER TABLE `productos_terminados` DISABLE KEYS */;
INSERT INTO `productos_terminados` VALUES (1,'84e8ac4f-2613-11f1-9474-c01850d072b8','Concha de Crema Pastelera','Concha suave rellena de crema pastelera clásica',24.00,0.00,20.00,'activo','2026-03-22 11:21:10','2026-03-22 11:21:10'),(2,'84e8d2df-2613-11f1-9474-c01850d072b8','Concha de Chocolate','Concha de cocoa rellena de crema de chocolate',26.00,0.00,20.00,'activo','2026-03-22 11:21:10','2026-03-22 11:21:10'),(3,'84e8d5db-2613-11f1-9474-c01850d072b8','Cuernito de Cajeta y Queso','Cuernito hojaldrado relleno de cajeta y queso crema',26.00,0.00,20.00,'activo','2026-03-22 11:21:10','2026-03-22 11:21:10'),(4,'84e8d72f-2613-11f1-9474-c01850d072b8','Dona de Crema de Avellana','Dona con glaseado de chocolate rellena de crema de avellana',28.00,0.00,15.00,'activo','2026-03-22 11:21:10','2026-03-22 11:21:10'),(5,'84e8d842-2613-11f1-9474-c01850d072b8','Cuernito de Dulce de Leche','Cuernito hojaldrado relleno de dulce de leche',25.00,0.00,20.00,'activo','2026-03-22 11:21:10','2026-03-22 11:21:10'),(6,'84e8d976-2613-11f1-9474-c01850d072b8','Polvorón de Crema de Limón','Polvorón de mantequilla relleno de crema de limón',26.00,0.00,15.00,'activo','2026-03-22 11:21:10','2026-03-22 11:21:10'),(7,'84e8da8e-2613-11f1-9474-c01850d072b8','Trenza de Canela y Piloncillo','Trenza de masa dulce rellena de piloncillo y canela',24.00,0.00,15.00,'activo','2026-03-22 11:21:10','2026-03-22 11:21:10'),(8,'84e8dbb3-2613-11f1-9474-c01850d072b8','Volcán de Chocolate','Pan individual de cocoa con centro de crema de chocolate',30.00,0.00,15.00,'activo','2026-03-22 11:21:10','2026-03-22 11:21:10'),(9,'84e8dd04-2613-11f1-9474-c01850d072b8','Mogote de Requesón y Vainilla','Pan redondo esponjoso relleno de requesón con vainilla',24.00,0.00,20.00,'activo','2026-03-22 11:21:10','2026-03-22 11:21:10'),(10,'84e8de28-2613-11f1-9474-c01850d072b8','Dona de Mermelada de Fresa','Dona con azúcar glass rellena de mermelada de fresa',22.00,0.00,20.00,'activo','2026-03-22 11:21:10','2026-03-22 11:21:10'),(11,'84e8df44-2613-11f1-9474-c01850d072b8','Cuernito de Crema Pastelera y Fresa','Cuernito hojaldrado con doble relleno de crema pastelera y fresa',28.00,0.00,15.00,'activo','2026-03-22 11:21:10','2026-03-22 11:21:10'),(12,'84e8e05d-2613-11f1-9474-c01850d072b8','Brioche de Mantequilla y Azúcar Glass','Pan brioche relleno de mantequilla y cubierto de azúcar glass',20.00,0.00,25.00,'activo','2026-03-22 11:21:10','2026-03-22 11:21:10');
/*!40000 ALTER TABLE `productos_terminados` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `proveedores`
--

DROP TABLE IF EXISTS `proveedores`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `proveedores` (
  `id_proveedor` int NOT NULL AUTO_INCREMENT,
  `uuid_proveedor` varchar(36) NOT NULL,
  `nombre` varchar(150) NOT NULL,
  `rfc` varchar(13) DEFAULT NULL,
  `contacto` varchar(120) DEFAULT NULL,
  `telefono` varchar(20) DEFAULT NULL,
  `email` varchar(150) DEFAULT NULL,
  `direccion` text,
  `estatus` enum('activo','inactivo') NOT NULL,
  `creado_en` datetime NOT NULL,
  `actualizado_en` datetime NOT NULL,
  `creado_por` int DEFAULT NULL,
  PRIMARY KEY (`id_proveedor`),
  UNIQUE KEY `uuid_proveedor` (`uuid_proveedor`),
  UNIQUE KEY `rfc` (`rfc`),
  KEY `creado_por` (`creado_por`),
  CONSTRAINT `proveedores_ibfk_1` FOREIGN KEY (`creado_por`) REFERENCES `usuarios` (`id_usuario`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `proveedores`
--

LOCK TABLES `proveedores` WRITE;
/*!40000 ALTER TABLE `proveedores` DISABLE KEYS */;
/*!40000 ALTER TABLE `proveedores` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `recetas`
--

DROP TABLE IF EXISTS `recetas`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `recetas` (
  `id_receta` int NOT NULL AUTO_INCREMENT,
  `id_producto` int DEFAULT NULL COMMENT 'Producto terminado que produce esta receta',
  `uuid_receta` varchar(36) NOT NULL,
  `nombre` varchar(120) NOT NULL,
  `descripcion` text,
  `rendimiento` decimal(10,2) NOT NULL,
  `unidad_rendimiento` varchar(20) NOT NULL,
  `precio_venta` decimal(10,2) DEFAULT NULL,
  `estatus` enum('activo','inactivo') NOT NULL,
  `creado_en` datetime NOT NULL,
  `actualizado_en` datetime NOT NULL,
  `creado_por` int DEFAULT NULL,
  `id_tamanio` int DEFAULT NULL COMMENT 'Tamaño de charola al que corresponde esta receta. NULL = receta sin tamaño de charola.',
  PRIMARY KEY (`id_receta`),
  UNIQUE KEY `uuid_receta` (`uuid_receta`),
  UNIQUE KEY `uq_producto_tamanio` (`id_producto`,`id_tamanio`),
  KEY `creado_por` (`creado_por`),
  KEY `fk_receta_producto` (`id_producto`),
  KEY `fk_receta_tamanio` (`id_tamanio`),
  CONSTRAINT `fk_receta_producto` FOREIGN KEY (`id_producto`) REFERENCES `productos` (`id_producto`) ON DELETE SET NULL,
  CONSTRAINT `fk_receta_tamanio` FOREIGN KEY (`id_tamanio`) REFERENCES `tamanios_charola` (`id_tamanio`) ON DELETE SET NULL,
  CONSTRAINT `recetas_ibfk_1` FOREIGN KEY (`creado_por`) REFERENCES `usuarios` (`id_usuario`)
) ENGINE=InnoDB AUTO_INCREMENT=53 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `recetas`
--

LOCK TABLES `recetas` WRITE;
/*!40000 ALTER TABLE `recetas` DISABLE KEYS */;
INSERT INTO `recetas` VALUES (1,1,'84bf5c5f-2613-11f1-9474-c01850d072b8','Concha de Crema Pastelera','Concha suave con cubierta de azúcar, rellena de crema pastelera clásica',12.00,'pza',24.00,'activo','2026-03-22 11:21:09','2026-03-22 11:21:09',1,NULL),(2,2,'84c00cea-2613-11f1-9474-c01850d072b8','Concha de Chocolate','Concha con cubierta de cocoa, rellena de crema de chocolate',12.00,'pza',26.00,'activo','2026-03-22 11:21:09','2026-03-23 20:16:19',1,NULL),(3,3,'84c00fa7-2613-11f1-9474-c01850d072b8','Cuernito de Cajeta y Queso','Cuernito hojaldrado relleno de cajeta con queso crema',14.00,'pza',26.00,'activo','2026-03-22 11:21:09','2026-03-22 11:21:09',1,NULL),(4,4,'84c010d4-2613-11f1-9474-c01850d072b8','Dona de Crema de Avellana','Dona esponjosa con glaseado de chocolate, rellena de crema de avellana',10.00,'pza',28.00,'activo','2026-03-22 11:21:09','2026-03-22 11:21:09',1,NULL),(5,5,'84c011fa-2613-11f1-9474-c01850d072b8','Cuernito de Dulce de Leche','Cuernito hojaldrado relleno de dulce de leche cremoso',14.00,'pza',25.00,'activo','2026-03-22 11:21:09','2026-03-22 11:21:09',1,NULL),(6,6,'84c01311-2613-11f1-9474-c01850d072b8','Polvorón de Crema de Limón','Polvorón suave con base de mantequilla, relleno de crema de limón fresca',10.00,'pza',26.00,'activo','2026-03-22 11:21:09','2026-03-22 11:21:09',1,NULL),(7,7,'84c014a3-2613-11f1-9474-c01850d072b8','Trenza de Canela y Piloncillo','Trenza de masa dulce con canela, rellena de piloncillo derretido',10.00,'pza',24.00,'activo','2026-03-22 11:21:09','2026-03-22 11:21:09',1,NULL),(8,8,'84c01646-2613-11f1-9474-c01850d072b8','Volcán de Chocolate','Pan individual de cocoa con centro de crema de chocolate',10.00,'pza',30.00,'activo','2026-03-22 11:21:09','2026-03-22 11:21:09',1,NULL),(9,9,'84c0191d-2613-11f1-9474-c01850d072b8','Mogote de Requesón y Vainilla','Pan redondo y esponjoso relleno de requesón suavizado con vainilla',12.00,'pza',24.00,'activo','2026-03-22 11:21:09','2026-03-22 11:21:09',1,NULL),(10,10,'84c01b2b-2613-11f1-9474-c01850d072b8','Dona de Mermelada de Fresa','Dona esponjosa con azúcar glass, rellena de mermelada de fresa',12.00,'pza',22.00,'activo','2026-03-22 11:21:09','2026-03-22 11:21:09',1,NULL),(11,11,'84c01c58-2613-11f1-9474-c01850d072b8','Cuernito de Crema Pastelera y Fresa','Cuernito hojaldrado con doble relleno de crema pastelera y mermelada de fresa',12.00,'pza',28.00,'activo','2026-03-22 11:21:09','2026-03-22 11:21:09',1,NULL),(12,12,'84c01e4e-2613-11f1-9474-c01850d072b8','Brioche de Mantequilla y Azúcar Glass','Pan tipo brioche esponjoso relleno de mantequilla y cubierto de azúcar glass',16.00,'pza',20.00,'activo','2026-03-22 11:21:09','2026-03-24 14:56:51',1,NULL),(13,NULL,'6f56eaeb-3261-4379-a793-b206f4d1943e','Salvador','bla bla bla',12.00,'pza',15.00,'activo','2026-03-23 20:13:06','2026-03-23 20:13:06',NULL,NULL),(14,8,'9e3edc23-d65c-4ff9-9064-0bbc92a423d5','Volcan de Chocolate - 12 piezas','bla bla',12.00,'pza',12.00,'activo','2026-03-24 09:38:32','2026-03-24 09:38:32',NULL,NULL),(16,12,'c2c50642-c1f6-4a90-80aa-b2bc93fc822a','Brionche para 2','bla bla',2.00,'pza',50.00,'activo','2026-03-24 15:11:43','2026-03-24 15:12:24',NULL,NULL),(17,1,'47535891-2959-11f1-828b-c01850d072b8','Concha Crema Pastelera — Charola Chica','Charola de 4 conchas rellenas de crema pastelera',4.00,'pza',96.00,'activo','2026-03-26 15:18:05','2026-03-26 15:18:05',1,1),(18,1,'475364c3-2959-11f1-828b-c01850d072b8','Concha Crema Pastelera — Charola Mediana','Charola de 8 conchas rellenas de crema pastelera',8.00,'pza',192.00,'activo','2026-03-26 15:18:05','2026-03-26 15:18:05',1,2),(19,1,'475366d7-2959-11f1-828b-c01850d072b8','Concha Crema Pastelera — Charola Grande','Charola de 12 conchas rellenas de crema pastelera',12.00,'pza',288.00,'activo','2026-03-26 15:18:05','2026-03-26 15:18:05',1,3),(20,2,'475653c0-2959-11f1-828b-c01850d072b8','Concha Chocolate — Charola Chica','Charola de 4 conchas de chocolate',4.00,'pza',104.00,'activo','2026-03-26 15:18:05','2026-03-26 15:18:05',1,1),(21,2,'47566302-2959-11f1-828b-c01850d072b8','Concha Chocolate — Charola Mediana','Charola de 8 conchas de chocolate',8.00,'pza',208.00,'activo','2026-03-26 15:18:05','2026-03-26 15:18:05',1,2),(22,2,'47566736-2959-11f1-828b-c01850d072b8','Concha Chocolate — Charola Grande','Charola de 12 conchas de chocolate',12.00,'pza',312.00,'activo','2026-03-26 15:18:05','2026-03-26 15:18:05',1,3),(23,3,'4759dafa-2959-11f1-828b-c01850d072b8','Cuernito Cajeta Queso — Charola Chica','Charola de 4 cuernitos de cajeta y queso',4.00,'pza',104.00,'activo','2026-03-26 15:18:05','2026-03-26 15:18:05',1,1),(24,3,'4759e3c0-2959-11f1-828b-c01850d072b8','Cuernito Cajeta Queso — Charola Mediana','Charola de 8 cuernitos de cajeta y queso',8.00,'pza',208.00,'activo','2026-03-26 15:18:05','2026-03-26 15:18:05',1,2),(25,3,'4759e64f-2959-11f1-828b-c01850d072b8','Cuernito Cajeta Queso — Charola Grande','Charola de 12 cuernitos de cajeta y queso',12.00,'pza',312.00,'activo','2026-03-26 15:18:05','2026-03-26 15:18:05',1,3),(26,4,'475d144c-2959-11f1-828b-c01850d072b8','Dona Avellana — Charola Chica','Charola de 4 donas de crema de avellana',4.00,'pza',112.00,'activo','2026-03-26 15:18:05','2026-03-26 15:18:05',1,1),(27,4,'475d1dd4-2959-11f1-828b-c01850d072b8','Dona Avellana — Charola Mediana','Charola de 8 donas de crema de avellana',8.00,'pza',224.00,'activo','2026-03-26 15:18:05','2026-03-26 15:18:05',1,2),(28,4,'475d1fe2-2959-11f1-828b-c01850d072b8','Dona Avellana — Charola Grande','Charola de 12 donas de crema de avellana',12.00,'pza',336.00,'activo','2026-03-26 15:18:05','2026-03-26 15:18:05',1,3),(29,5,'47699731-2959-11f1-828b-c01850d072b8','Cuernito Dulce de Leche — Charola Chica','Charola de 4 cuernitos de dulce de leche',4.00,'pza',100.00,'activo','2026-03-26 15:18:05','2026-03-26 15:18:05',1,1),(30,5,'4769a279-2959-11f1-828b-c01850d072b8','Cuernito Dulce de Leche — Charola Mediana','Charola de 8 cuernitos de dulce de leche',8.00,'pza',200.00,'activo','2026-03-26 15:18:05','2026-03-26 15:18:05',1,2),(31,5,'4769a500-2959-11f1-828b-c01850d072b8','Cuernito Dulce de Leche — Charola Grande','Charola de 12 cuernitos de dulce de leche',12.00,'pza',300.00,'activo','2026-03-26 15:18:05','2026-03-26 15:18:05',1,3),(32,6,'4774ff13-2959-11f1-828b-c01850d072b8','Polvorón Limón — Charola Chica','Charola de 4 polvorones de crema de limón',4.00,'pza',104.00,'activo','2026-03-26 15:18:05','2026-03-26 15:18:05',1,1),(33,6,'477c63e6-2959-11f1-828b-c01850d072b8','Polvorón Limón — Charola Mediana','Charola de 8 polvorones de crema de limón',8.00,'pza',208.00,'activo','2026-03-26 15:18:05','2026-03-26 15:18:05',1,2),(34,6,'477c68e8-2959-11f1-828b-c01850d072b8','Polvorón Limón — Charola Grande','Charola de 12 polvorones de crema de limón',12.00,'pza',312.00,'activo','2026-03-26 15:18:05','2026-03-26 15:18:05',1,3),(35,7,'4783ea3e-2959-11f1-828b-c01850d072b8','Trenza Canela Piloncillo — Charola Chica','Charola de 4 trenzas de canela y piloncillo',4.00,'pza',96.00,'activo','2026-03-26 15:18:05','2026-03-26 15:18:05',1,1),(36,7,'4783f244-2959-11f1-828b-c01850d072b8','Trenza Canela Piloncillo — Charola Mediana','Charola de 8 trenzas de canela y piloncillo',8.00,'pza',192.00,'activo','2026-03-26 15:18:05','2026-03-26 15:18:05',1,2),(37,7,'4783f426-2959-11f1-828b-c01850d072b8','Trenza Canela Piloncillo — Charola Grande','Charola de 12 trenzas de canela y piloncillo',12.00,'pza',288.00,'activo','2026-03-26 15:18:05','2026-03-26 15:18:05',1,3),(38,8,'47865367-2959-11f1-828b-c01850d072b8','Volcán Chocolate — Charola Chica','Charola de 4 volcanes de chocolate',4.00,'pza',120.00,'activo','2026-03-26 15:18:05','2026-03-26 15:18:05',1,1),(39,8,'47865b53-2959-11f1-828b-c01850d072b8','Volcán Chocolate — Charola Mediana','Charola de 8 volcanes de chocolate',8.00,'pza',240.00,'activo','2026-03-26 15:18:05','2026-03-26 15:18:05',1,2),(40,8,'47865d17-2959-11f1-828b-c01850d072b8','Volcán Chocolate — Charola Grande','Charola de 12 volcanes de chocolate',12.00,'pza',360.00,'activo','2026-03-26 15:18:05','2026-03-26 15:18:05',1,3),(41,9,'47895029-2959-11f1-828b-c01850d072b8','Mogote Requesón — Charola Chica','Charola de 4 mogotes de requesón y vainilla',4.00,'pza',96.00,'activo','2026-03-26 15:18:05','2026-03-26 15:18:05',1,1),(42,9,'478959d3-2959-11f1-828b-c01850d072b8','Mogote Requesón — Charola Mediana','Charola de 8 mogotes de requesón y vainilla',8.00,'pza',192.00,'activo','2026-03-26 15:18:05','2026-03-26 15:18:05',1,2),(43,9,'47895cff-2959-11f1-828b-c01850d072b8','Mogote Requesón — Charola Grande','Charola de 12 mogotes de requesón y vainilla',12.00,'pza',288.00,'activo','2026-03-26 15:18:05','2026-03-26 15:18:05',1,3),(44,10,'478d8985-2959-11f1-828b-c01850d072b8','Dona Fresa — Charola Chica','Charola de 4 donas de mermelada de fresa',4.00,'pza',88.00,'activo','2026-03-26 15:18:05','2026-03-26 15:18:05',1,1),(45,10,'478d962e-2959-11f1-828b-c01850d072b8','Dona Fresa — Charola Mediana','Charola de 8 donas de mermelada de fresa',8.00,'pza',176.00,'activo','2026-03-26 15:18:05','2026-03-26 15:18:05',1,2),(46,10,'478d98ba-2959-11f1-828b-c01850d072b8','Dona Fresa — Charola Grande','Charola de 12 donas de mermelada de fresa',12.00,'pza',264.00,'activo','2026-03-26 15:18:05','2026-03-26 15:18:05',1,3),(47,11,'47924c0c-2959-11f1-828b-c01850d072b8','Cuernito C.Pastelera Fresa — Charola Chica','Charola de 4 cuernitos de crema pastelera y fresa',4.00,'pza',112.00,'activo','2026-03-26 15:18:05','2026-03-26 15:18:05',1,1),(48,11,'4792555b-2959-11f1-828b-c01850d072b8','Cuernito C.Pastelera Fresa — Charola Mediana','Charola de 8 cuernitos de crema pastelera y fresa',8.00,'pza',224.00,'activo','2026-03-26 15:18:05','2026-03-26 15:18:05',1,2),(49,11,'479258e4-2959-11f1-828b-c01850d072b8','Cuernito C.Pastelera Fresa — Charola Grande','Charola de 12 cuernitos de crema pastelera y fresa',12.00,'pza',336.00,'activo','2026-03-26 15:18:05','2026-03-26 15:18:05',1,3),(50,12,'4794cf24-2959-11f1-828b-c01850d072b8','Brioche Mantequilla — Charola Chica','Charola de 4 brioches de mantequilla y azúcar glass',4.00,'pza',80.00,'activo','2026-03-26 15:18:05','2026-03-26 15:18:05',1,1),(51,12,'4794d82a-2959-11f1-828b-c01850d072b8','Brioche Mantequilla — Charola Mediana','Charola de 8 brioches de mantequilla y azúcar glass',8.00,'pza',160.00,'activo','2026-03-26 15:18:05','2026-03-26 15:18:05',1,2),(52,12,'4794da3a-2959-11f1-828b-c01850d072b8','Brioche Mantequilla — Charola Grande','Charola de 12 brioches de mantequilla y azúcar glass',12.00,'pza',240.00,'activo','2026-03-26 15:18:05','2026-03-26 15:18:05',1,3);
/*!40000 ALTER TABLE `recetas` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `roles`
--

DROP TABLE IF EXISTS `roles`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `roles` (
  `id_rol` smallint NOT NULL AUTO_INCREMENT,
  `clave_rol` varchar(10) NOT NULL,
  `nombre_rol` varchar(50) NOT NULL,
  `descripcion` text,
  PRIMARY KEY (`id_rol`),
  UNIQUE KEY `clave_rol` (`clave_rol`)
) ENGINE=InnoDB AUTO_INCREMENT=5 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `roles`
--

LOCK TABLES `roles` WRITE;
/*!40000 ALTER TABLE `roles` DISABLE KEYS */;
INSERT INTO `roles` VALUES (1,'admin','Administrador','Acceso total al sistema'),(2,'empleado','Empleado','Acceso general de empleado'),(3,'panadero','Panadero','Acceso a módulos de producción'),(4,'cliente','Cliente','Acceso al portal de pedidos en línea');
/*!40000 ALTER TABLE `roles` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `salidas_efectivo`
--

DROP TABLE IF EXISTS `salidas_efectivo`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `salidas_efectivo` (
  `id_salida` int NOT NULL AUTO_INCREMENT,
  `folio_salida` varchar(20) NOT NULL,
  `id_proveedor` int DEFAULT NULL,
  `categoria` enum('compra_insumos','servicios_utilities','mantenimiento','otros') NOT NULL,
  `descripcion` varchar(255) NOT NULL,
  `monto` decimal(12,2) NOT NULL,
  `fecha_salida` date NOT NULL,
  `estado` enum('pendiente','aprobada','rechazada') NOT NULL,
  `id_corte` int DEFAULT NULL,
  `registrado_por` int NOT NULL,
  `aprobado_por` int DEFAULT NULL,
  `creado_en` datetime NOT NULL,
  `actualizado_en` datetime NOT NULL,
  PRIMARY KEY (`id_salida`),
  UNIQUE KEY `folio_salida` (`folio_salida`),
  KEY `aprobado_por` (`aprobado_por`),
  KEY `id_corte` (`id_corte`),
  KEY `id_proveedor` (`id_proveedor`),
  KEY `registrado_por` (`registrado_por`),
  CONSTRAINT `salidas_efectivo_ibfk_1` FOREIGN KEY (`aprobado_por`) REFERENCES `usuarios` (`id_usuario`) ON DELETE SET NULL,
  CONSTRAINT `salidas_efectivo_ibfk_2` FOREIGN KEY (`id_corte`) REFERENCES `cortes_diarios` (`id_corte`) ON DELETE SET NULL,
  CONSTRAINT `salidas_efectivo_ibfk_3` FOREIGN KEY (`id_proveedor`) REFERENCES `proveedores` (`id_proveedor`) ON DELETE SET NULL,
  CONSTRAINT `salidas_efectivo_ibfk_4` FOREIGN KEY (`registrado_por`) REFERENCES `usuarios` (`id_usuario`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `salidas_efectivo`
--

LOCK TABLES `salidas_efectivo` WRITE;
/*!40000 ALTER TABLE `salidas_efectivo` DISABLE KEYS */;
/*!40000 ALTER TABLE `salidas_efectivo` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `sesiones`
--

DROP TABLE IF EXISTS `sesiones`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `sesiones` (
  `id_sesion` varchar(64) NOT NULL,
  `id_usuario` int NOT NULL,
  `ip_inicio` varchar(45) DEFAULT NULL,
  `user_agent` varchar(255) DEFAULT NULL,
  `csrf_token` varchar(64) NOT NULL,
  `activa` tinyint(1) NOT NULL,
  `expira_en` datetime NOT NULL,
  `creado_en` datetime NOT NULL,
  `ultimo_acceso` datetime NOT NULL,
  PRIMARY KEY (`id_sesion`),
  KEY `id_usuario` (`id_usuario`),
  CONSTRAINT `sesiones_ibfk_1` FOREIGN KEY (`id_usuario`) REFERENCES `usuarios` (`id_usuario`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `sesiones`
--

LOCK TABLES `sesiones` WRITE;
/*!40000 ALTER TABLE `sesiones` DISABLE KEYS */;
/*!40000 ALTER TABLE `sesiones` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `tamanios_charola`
--

DROP TABLE IF EXISTS `tamanios_charola`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `tamanios_charola` (
  `id_tamanio` int NOT NULL AUTO_INCREMENT,
  `nombre` varchar(40) NOT NULL COMMENT 'Ej: Charola Chica, Charola Mediana, Charola Grande',
  `capacidad` tinyint NOT NULL COMMENT 'Número de panes que caben: 4, 8 o 12',
  `descripcion` text,
  `estatus` enum('activo','inactivo') NOT NULL DEFAULT 'activo',
  `creado_en` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id_tamanio`),
  UNIQUE KEY `uq_capacidad` (`capacidad`)
) ENGINE=InnoDB AUTO_INCREMENT=13 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci COMMENT='Tamaños de charola disponibles para armar cajas de pan.';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `tamanios_charola`
--

LOCK TABLES `tamanios_charola` WRITE;
/*!40000 ALTER TABLE `tamanios_charola` DISABLE KEYS */;
INSERT INTO `tamanios_charola` VALUES (1,'Charola Chica',4,'Caja para 4 panes','activo','2026-03-26 14:27:32'),(2,'Charola Mediana',8,'Caja para 8 panes','activo','2026-03-26 14:27:32'),(3,'Charola Grande',12,'Caja para 12 panes','activo','2026-03-26 14:27:32');
/*!40000 ALTER TABLE `tamanios_charola` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `tickets`
--

DROP TABLE IF EXISTS `tickets`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `tickets` (
  `id_ticket` int NOT NULL AUTO_INCREMENT,
  `id_venta` int NOT NULL,
  `contenido_json` json NOT NULL,
  `impreso` tinyint(1) NOT NULL,
  `generado_en` datetime NOT NULL,
  PRIMARY KEY (`id_ticket`),
  UNIQUE KEY `id_venta` (`id_venta`),
  CONSTRAINT `tickets_ibfk_1` FOREIGN KEY (`id_venta`) REFERENCES `ventas` (`id_venta`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `tickets`
--

LOCK TABLES `tickets` WRITE;
/*!40000 ALTER TABLE `tickets` DISABLE KEYS */;
/*!40000 ALTER TABLE `tickets` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `unidades_presentacion`
--

DROP TABLE IF EXISTS `unidades_presentacion`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `unidades_presentacion` (
  `id_unidad` int NOT NULL AUTO_INCREMENT,
  `id_materia` int NOT NULL,
  `nombre` varchar(80) NOT NULL,
  `simbolo` varchar(20) NOT NULL,
  `factor_a_base` decimal(14,2) NOT NULL,
  `uso` enum('compra','receta','ambos') NOT NULL,
  `activo` tinyint(1) NOT NULL DEFAULT '1',
  `creado_en` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id_unidad`),
  UNIQUE KEY `uq_unidad_materia_simbolo` (`id_materia`,`simbolo`),
  CONSTRAINT `unidades_presentacion_ibfk_1` FOREIGN KEY (`id_materia`) REFERENCES `materias_primas` (`id_materia`) ON DELETE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=78 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `unidades_presentacion`
--

LOCK TABLES `unidades_presentacion` WRITE;
/*!40000 ALTER TABLE `unidades_presentacion` DISABLE KEYS */;
INSERT INTO `unidades_presentacion` VALUES (1,1,'Kilogramo','kg',1000.00,'compra',1,'2026-03-24 15:03:49'),(2,1,'Saco 25 kg','saco',25000.00,'compra',1,'2026-03-24 15:03:49'),(3,1,'Gramo','g',1.00,'receta',1,'2026-03-24 15:03:49'),(4,1,'Taza cernida','taza',120.00,'receta',1,'2026-03-24 15:03:49'),(5,2,'Kilogramo','kg',1000.00,'compra',1,'2026-03-24 15:03:49'),(6,2,'Gramo','g',1.00,'receta',1,'2026-03-24 15:03:49'),(7,2,'Cucharada','cda',12.00,'receta',1,'2026-03-24 15:03:49'),(8,2,'Taza','taza',200.00,'receta',1,'2026-03-24 15:03:49'),(9,3,'Kilogramo','kg',1000.00,'compra',1,'2026-03-24 15:03:49'),(10,3,'Gramo','g',1.00,'receta',1,'2026-03-24 15:03:49'),(11,3,'Barra 90 g','barra',90.00,'receta',1,'2026-03-24 15:03:49'),(12,3,'Cucharada','cda',14.00,'receta',1,'2026-03-24 15:03:49'),(13,4,'Galón (3.785 L)','gal',3785.00,'compra',1,'2026-03-24 15:03:49'),(14,4,'Litro','lt',1000.00,'ambos',1,'2026-03-24 15:03:49'),(15,4,'Taza (240 ml)','taza',240.00,'receta',1,'2026-03-24 15:03:49'),(16,4,'Mililitro','ml',1.00,'receta',1,'2026-03-24 15:03:49'),(17,5,'Kilogramo','kg',1000.00,'compra',1,'2026-03-24 15:03:49'),(18,5,'Gramo','g',1.00,'receta',1,'2026-03-24 15:03:49'),(19,5,'Cucharadita','cdta',3.00,'receta',1,'2026-03-24 15:03:49'),(20,6,'Kilo (~16-17 pzas)','kg',16.67,'compra',1,'2026-03-24 15:03:49'),(21,6,'Docena','doc',12.00,'compra',1,'2026-03-24 15:03:49'),(22,6,'Caja 30 pzas','caja',30.00,'compra',1,'2026-03-24 15:03:49'),(23,6,'Pieza','pza',1.00,'receta',1,'2026-03-24 15:03:49'),(24,7,'Kilogramo','kg',1000.00,'compra',1,'2026-03-24 15:03:49'),(25,7,'Gramo','g',1.00,'receta',1,'2026-03-24 15:03:49'),(26,7,'Cucharadita','cdta',5.00,'receta',1,'2026-03-24 15:03:49'),(27,7,'Pizca','pizca',0.50,'receta',1,'2026-03-24 15:03:49'),(28,8,'Litro','lt',1000.00,'compra',1,'2026-03-24 15:03:49'),(29,8,'Mililitro','ml',1.00,'receta',1,'2026-03-24 15:03:49'),(30,8,'Cucharadita','cdta',5.00,'receta',1,'2026-03-24 15:03:49'),(31,9,'Kilogramo','kg',1000.00,'compra',1,'2026-03-24 15:03:49'),(32,9,'Gramo','g',1.00,'receta',1,'2026-03-24 15:03:49'),(33,9,'Cucharada','cda',7.00,'receta',1,'2026-03-24 15:03:49'),(34,9,'Taza','taza',85.00,'receta',1,'2026-03-24 15:03:49'),(35,10,'Bolsa 500 g','bolsa',500.00,'compra',1,'2026-03-24 15:03:49'),(36,10,'Gramo','g',1.00,'receta',1,'2026-03-24 15:03:49'),(37,10,'Cucharadita','cdta',2.50,'receta',1,'2026-03-24 15:03:49'),(38,10,'Cucharada','cda',7.00,'receta',1,'2026-03-24 15:03:49'),(39,11,'Kilogramo','kg',1000.00,'compra',1,'2026-03-24 15:03:49'),(40,11,'Barra 190 g','barra',190.00,'compra',1,'2026-03-24 15:03:49'),(41,11,'Gramo','g',1.00,'receta',1,'2026-03-24 15:03:49'),(42,11,'Cucharada','cda',15.00,'receta',1,'2026-03-24 15:03:49'),(43,12,'Kilogramo','kg',1000.00,'compra',1,'2026-03-24 15:03:49'),(44,12,'Frasco 500 g','frasco',500.00,'compra',1,'2026-03-24 15:03:49'),(45,12,'Gramo','g',1.00,'receta',1,'2026-03-24 15:03:49'),(46,12,'Cucharada','cda',20.00,'receta',1,'2026-03-24 15:03:49'),(47,13,'Kilogramo','kg',1000.00,'compra',1,'2026-03-24 15:03:49'),(48,13,'Gramo','g',1.00,'receta',1,'2026-03-24 15:03:49'),(49,13,'Cucharada','cda',25.00,'receta',1,'2026-03-24 15:03:49'),(50,14,'Kilogramo','kg',1000.00,'compra',1,'2026-03-24 15:03:49'),(51,14,'Frasco 370 g','frasco',370.00,'compra',1,'2026-03-24 15:03:49'),(52,14,'Gramo','g',1.00,'receta',1,'2026-03-24 15:03:49'),(53,14,'Cucharada','cda',20.00,'receta',1,'2026-03-24 15:03:49'),(54,15,'Kilogramo','kg',1000.00,'compra',1,'2026-03-24 15:03:49'),(55,15,'Frasco 400 g','frasco',400.00,'compra',1,'2026-03-24 15:03:49'),(56,15,'Gramo','g',1.00,'receta',1,'2026-03-24 15:03:49'),(57,15,'Cucharada','cda',20.00,'receta',1,'2026-03-24 15:03:49'),(58,16,'Kilogramo','kg',1000.00,'compra',1,'2026-03-24 15:03:49'),(59,16,'Frasco 450 g','frasco',450.00,'compra',1,'2026-03-24 15:03:49'),(60,16,'Gramo','g',1.00,'receta',1,'2026-03-24 15:03:49'),(61,16,'Cucharada','cda',20.00,'receta',1,'2026-03-24 15:03:49'),(62,17,'Kilogramo','kg',1000.00,'compra',1,'2026-03-24 15:03:49'),(63,17,'Gramo','g',1.00,'receta',1,'2026-03-24 15:03:49'),(64,17,'Cucharada','cda',20.00,'receta',1,'2026-03-24 15:03:49'),(65,18,'Kilogramo','kg',1000.00,'compra',1,'2026-03-24 15:03:49'),(66,18,'Cono 250 g','cono',250.00,'compra',1,'2026-03-24 15:03:49'),(67,18,'Gramo','g',1.00,'receta',1,'2026-03-24 15:03:49'),(68,18,'Cucharada','cda',12.00,'receta',1,'2026-03-24 15:03:49'),(69,19,'Kilogramo','kg',1000.00,'compra',1,'2026-03-24 15:03:49'),(70,19,'Barra 250 g','barra',250.00,'compra',1,'2026-03-24 15:03:49'),(71,19,'Gramo','g',1.00,'receta',1,'2026-03-24 15:03:49'),(72,19,'Cucharada','cda',25.00,'receta',1,'2026-03-24 15:03:49'),(73,20,'Kilogramo','kg',1000.00,'compra',1,'2026-03-24 15:03:49'),(74,20,'Bolsa 500 g','bolsa',500.00,'compra',1,'2026-03-24 15:03:49'),(75,20,'Gramo','g',1.00,'receta',1,'2026-03-24 15:03:49'),(76,20,'Cucharada','cda',10.00,'receta',1,'2026-03-24 15:03:49'),(77,20,'Taza','taza',120.00,'receta',1,'2026-03-24 15:03:49');
/*!40000 ALTER TABLE `unidades_presentacion` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `usuarios`
--

DROP TABLE IF EXISTS `usuarios`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `usuarios` (
  `id_usuario` int NOT NULL AUTO_INCREMENT,
  `uuid_usuario` varchar(36) NOT NULL,
  `nombre_completo` varchar(120) NOT NULL,
  `username` varchar(60) NOT NULL,
  `password_hash` varchar(255) NOT NULL,
  `id_rol` smallint NOT NULL,
  `estatus` enum('activo','inactivo','bloqueado') NOT NULL,
  `intentos_fallidos` smallint NOT NULL,
  `bloqueado_hasta` datetime DEFAULT NULL,
  `ultimo_login` datetime DEFAULT NULL,
  `token_2fa` varchar(10) DEFAULT NULL,
  `token_2fa_expira` datetime DEFAULT NULL,
  `cambio_pwd_req` tinyint(1) NOT NULL,
  `creado_en` datetime NOT NULL,
  `actualizado_en` datetime NOT NULL,
  `creado_por` int DEFAULT NULL,
  PRIMARY KEY (`id_usuario`),
  UNIQUE KEY `username` (`username`),
  UNIQUE KEY `uuid_usuario` (`uuid_usuario`),
  KEY `id_rol` (`id_rol`),
  KEY `creado_por` (`creado_por`),
  CONSTRAINT `usuarios_ibfk_2` FOREIGN KEY (`id_rol`) REFERENCES `roles` (`id_rol`),
  CONSTRAINT `usuarios_ibfk_3` FOREIGN KEY (`creado_por`) REFERENCES `usuarios` (`id_usuario`)
) ENGINE=InnoDB AUTO_INCREMENT=4 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `usuarios`
--

LOCK TABLES `usuarios` WRITE;
/*!40000 ALTER TABLE `usuarios` DISABLE KEYS */;
INSERT INTO `usuarios` VALUES (1,'1313435b-27e3-4ecc-b4ca-6628dd75813a','Salvador Esquivel','esquivelsalvador260@gmail.com','scrypt:32768:8:1$662xtVgk2gBClqmN$881ce4f22cba6ee12a66e3660af7efb0a4027a24a32d188beceff3eb562a5f0033d9879b91c8194d403d2e878d7ffb1522af4aac068ad3b793f8999ed7f8724b',1,'activo',0,NULL,'2026-03-26 11:46:37',NULL,NULL,0,'2026-03-17 13:41:47','2026-03-26 11:46:37',NULL),(2,'a2cf04f0-823d-4d4f-abfa-c3ffd1821cc4','Administrador','admin','scrypt:32768:8:1$3YY1waWeDgejMlVO$ac4ed6e51536eaa0c6e8d67b2f85660e8c3a875589994585f439ae6dbc347d8097b82344dd59de032b45adf3b9561bf1e0a191b2f7bf1a55587e75f2b68dc5b8',3,'activo',0,NULL,'2026-03-26 12:20:04',NULL,NULL,0,'2026-03-25 17:46:04','2026-03-26 12:20:04',NULL),(3,'16d02607-469b-4e6f-a0d5-28b766436048','cliente','cliente','scrypt:32768:8:1$8lfdFieGESH9M3Ou$832adaa5be22d7f3c7765a13c7e4d247b759e410faae5bb12c6a4d8ed2a829824646c0ded052b6c23b326ce7b7685a164d529d1659fa5d76f427eee04c106afe',4,'activo',0,NULL,'2026-03-26 12:18:27',NULL,NULL,0,'2026-03-26 11:17:47','2026-03-26 12:18:27',1);
/*!40000 ALTER TABLE `usuarios` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Temporary view structure for view `v_caja_pedido`
--

DROP TABLE IF EXISTS `v_caja_pedido`;
/*!50001 DROP VIEW IF EXISTS `v_caja_pedido`*/;
SET @saved_cs_client     = @@character_set_client;
/*!50503 SET character_set_client = utf8mb4 */;
/*!50001 CREATE VIEW `v_caja_pedido` AS SELECT 
 1 AS `id_pedido`,
 1 AS `tipo`,
 1 AS `tamanio`,
 1 AS `nombre_caja`,
 1 AS `capacidad`,
 1 AS `precio_venta`*/;
SET character_set_client = @saved_cs_client;

--
-- Temporary view structure for view `v_cajas_detalle`
--

DROP TABLE IF EXISTS `v_cajas_detalle`;
/*!50001 DROP VIEW IF EXISTS `v_cajas_detalle`*/;
SET @saved_cs_client     = @@character_set_client;
/*!50503 SET character_set_client = utf8mb4 */;
/*!50001 CREATE VIEW `v_cajas_detalle` AS SELECT 
 1 AS `id_caja`,
 1 AS `nombre_caja`,
 1 AS `tipo`,
 1 AS `tamanio`,
 1 AS `capacidad`,
 1 AS `precio_venta`,
 1 AS `estatus`,
 1 AS `productos`,
 1 AS `total_piezas`*/;
SET character_set_client = @saved_cs_client;

--
-- Temporary view structure for view `v_conteo_pedidos_por_estado`
--

DROP TABLE IF EXISTS `v_conteo_pedidos_por_estado`;
/*!50001 DROP VIEW IF EXISTS `v_conteo_pedidos_por_estado`*/;
SET @saved_cs_client     = @@character_set_client;
/*!50503 SET character_set_client = utf8mb4 */;
/*!50001 CREATE VIEW `v_conteo_pedidos_por_estado` AS SELECT 
 1 AS `estado`,
 1 AS `total`*/;
SET character_set_client = @saved_cs_client;

--
-- Temporary view structure for view `v_detalle_pedido`
--

DROP TABLE IF EXISTS `v_detalle_pedido`;
/*!50001 DROP VIEW IF EXISTS `v_detalle_pedido`*/;
SET @saved_cs_client     = @@character_set_client;
/*!50503 SET character_set_client = utf8mb4 */;
/*!50001 CREATE VIEW `v_detalle_pedido` AS SELECT 
 1 AS `id_pedido`,
 1 AS `producto_nombre`,
 1 AS `producto_descripcion`,
 1 AS `cantidad`,
 1 AS `precio_unitario`,
 1 AS `subtotal`*/;
SET character_set_client = @saved_cs_client;

--
-- Temporary view structure for view `v_historial_pedido`
--

DROP TABLE IF EXISTS `v_historial_pedido`;
/*!50001 DROP VIEW IF EXISTS `v_historial_pedido`*/;
SET @saved_cs_client     = @@character_set_client;
/*!50503 SET character_set_client = utf8mb4 */;
/*!50001 CREATE VIEW `v_historial_pedido` AS SELECT 
 1 AS `id_pedido`,
 1 AS `estado_antes`,
 1 AS `estado_despues`,
 1 AS `nota`,
 1 AS `creado_en`,
 1 AS `usuario_nombre`*/;
SET character_set_client = @saved_cs_client;

--
-- Temporary view structure for view `v_notificaciones_cliente`
--

DROP TABLE IF EXISTS `v_notificaciones_cliente`;
/*!50001 DROP VIEW IF EXISTS `v_notificaciones_cliente`*/;
SET @saved_cs_client     = @@character_set_client;
/*!50503 SET character_set_client = utf8mb4 */;
/*!50001 CREATE VIEW `v_notificaciones_cliente` AS SELECT 
 1 AS `id_notif`,
 1 AS `id_pedido`,
 1 AS `id_usuario`,
 1 AS `folio`,
 1 AS `mensaje`,
 1 AS `leida`,
 1 AS `creado_en`*/;
SET character_set_client = @saved_cs_client;

--
-- Temporary view structure for view `v_pedido_detalle_completo`
--

DROP TABLE IF EXISTS `v_pedido_detalle_completo`;
/*!50001 DROP VIEW IF EXISTS `v_pedido_detalle_completo`*/;
SET @saved_cs_client     = @@character_set_client;
/*!50503 SET character_set_client = utf8mb4 */;
/*!50001 CREATE VIEW `v_pedido_detalle_completo` AS SELECT 
 1 AS `id_pedido`,
 1 AS `id_detalle`,
 1 AS `producto_nombre`,
 1 AS `producto_descripcion`,
 1 AS `cantidad`,
 1 AS `precio_unitario`,
 1 AS `subtotal`*/;
SET character_set_client = @saved_cs_client;

--
-- Temporary view structure for view `v_pedidos_resumen`
--

DROP TABLE IF EXISTS `v_pedidos_resumen`;
/*!50001 DROP VIEW IF EXISTS `v_pedidos_resumen`*/;
SET @saved_cs_client     = @@character_set_client;
/*!50503 SET character_set_client = utf8mb4 */;
/*!50001 CREATE VIEW `v_pedidos_resumen` AS SELECT 
 1 AS `id_pedido`,
 1 AS `folio`,
 1 AS `estado`,
 1 AS `fecha_recogida`,
 1 AS `total_estimado`,
 1 AS `motivo_rechazo`,
 1 AS `creado_en`,
 1 AS `actualizado_en`,
 1 AS `id_cliente`,
 1 AS `tipo_caja`,
 1 AS `tamanio_nombre`,
 1 AS `capacidad`,
 1 AS `id_usuario`,
 1 AS `cliente_nombre`,
 1 AS `cliente_username`,
 1 AS `num_productos`,
 1 AS `total_piezas`,
 1 AS `atendido_por_nombre`*/;
SET character_set_client = @saved_cs_client;

--
-- Temporary view structure for view `v_recetas_explosion`
--

DROP TABLE IF EXISTS `v_recetas_explosion`;
/*!50001 DROP VIEW IF EXISTS `v_recetas_explosion`*/;
SET @saved_cs_client     = @@character_set_client;
/*!50503 SET character_set_client = utf8mb4 */;
/*!50001 CREATE VIEW `v_recetas_explosion` AS SELECT 
 1 AS `producto`,
 1 AS `receta`,
 1 AS `rendimiento`,
 1 AS `unidad_rendimiento`,
 1 AS `insumo`,
 1 AS `cantidad_requerida`,
 1 AS `unidad_base`,
 1 AS `orden`*/;
SET character_set_client = @saved_cs_client;

--
-- Temporary view structure for view `v_recetas_por_tamanio`
--

DROP TABLE IF EXISTS `v_recetas_por_tamanio`;
/*!50001 DROP VIEW IF EXISTS `v_recetas_por_tamanio`*/;
SET @saved_cs_client     = @@character_set_client;
/*!50503 SET character_set_client = utf8mb4 */;
/*!50001 CREATE VIEW `v_recetas_por_tamanio` AS SELECT 
 1 AS `id_receta`,
 1 AS `nombre_receta`,
 1 AS `nombre_producto`,
 1 AS `tamanio`,
 1 AS `piezas`,
 1 AS `rendimiento`,
 1 AS `ingrediente`,
 1 AS `cantidad_requerida`,
 1 AS `unidad`*/;
SET character_set_client = @saved_cs_client;

--
-- Table structure for table `ventas`
--

DROP TABLE IF EXISTS `ventas`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `ventas` (
  `id_venta` int NOT NULL AUTO_INCREMENT,
  `folio_venta` varchar(20) NOT NULL,
  `fecha_venta` datetime NOT NULL,
  `total` decimal(12,2) NOT NULL,
  `metodo_pago` enum('efectivo','tarjeta','transferencia','otro') NOT NULL,
  `cambio` decimal(10,2) DEFAULT NULL,
  `requiere_ticket` tinyint(1) NOT NULL,
  `estado` enum('abierta','completada','cancelada') NOT NULL,
  `vendedor_id` int NOT NULL,
  `id_corte` int DEFAULT NULL,
  `creado_en` datetime NOT NULL,
  PRIMARY KEY (`id_venta`),
  UNIQUE KEY `folio_venta` (`folio_venta`),
  KEY `id_corte` (`id_corte`),
  KEY `vendedor_id` (`vendedor_id`),
  CONSTRAINT `ventas_ibfk_1` FOREIGN KEY (`id_corte`) REFERENCES `cortes_diarios` (`id_corte`) ON DELETE SET NULL,
  CONSTRAINT `ventas_ibfk_2` FOREIGN KEY (`vendedor_id`) REFERENCES `usuarios` (`id_usuario`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `ventas`
--

LOCK TABLES `ventas` WRITE;
/*!40000 ALTER TABLE `ventas` DISABLE KEYS */;
/*!40000 ALTER TABLE `ventas` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Final view structure for view `v_caja_pedido`
--

/*!50001 DROP VIEW IF EXISTS `v_caja_pedido`*/;
/*!50001 SET @saved_cs_client          = @@character_set_client */;
/*!50001 SET @saved_cs_results         = @@character_set_results */;
/*!50001 SET @saved_col_connection     = @@collation_connection */;
/*!50001 SET character_set_client      = utf8mb4 */;
/*!50001 SET character_set_results     = utf8mb4 */;
/*!50001 SET collation_connection      = utf8mb4_0900_ai_ci */;
/*!50001 CREATE ALGORITHM=UNDEFINED */
/*!50013 DEFINER=`root`@`localhost` SQL SECURITY DEFINER */
/*!50001 VIEW `v_caja_pedido` AS select `p`.`id_pedido` AS `id_pedido`,(`p`.`tipo` collate utf8mb4_unicode_ci) AS `tipo`,(`t`.`nombre` collate utf8mb4_unicode_ci) AS `tamanio`,(`t`.`nombre` collate utf8mb4_unicode_ci) AS `nombre_caja`,`t`.`capacidad` AS `capacidad`,`p`.`total_estimado` AS `precio_venta` from (`pedidos` `p` join `tamanios_charola` `t` on((`t`.`id_tamanio` = `p`.`id_tamanio`))) */;
/*!50001 SET character_set_client      = @saved_cs_client */;
/*!50001 SET character_set_results     = @saved_cs_results */;
/*!50001 SET collation_connection      = @saved_col_connection */;

--
-- Final view structure for view `v_cajas_detalle`
--

/*!50001 DROP VIEW IF EXISTS `v_cajas_detalle`*/;
/*!50001 SET @saved_cs_client          = @@character_set_client */;
/*!50001 SET @saved_cs_results         = @@character_set_results */;
/*!50001 SET @saved_col_connection     = @@collation_connection */;
/*!50001 SET character_set_client      = utf8mb4 */;
/*!50001 SET character_set_results     = utf8mb4 */;
/*!50001 SET collation_connection      = utf8mb4_0900_ai_ci */;
/*!50001 CREATE ALGORITHM=UNDEFINED */
/*!50013 DEFINER=`root`@`localhost` SQL SECURITY DEFINER */
/*!50001 VIEW `v_cajas_detalle` AS select `c`.`id_caja` AS `id_caja`,`c`.`nombre` AS `nombre_caja`,`c`.`tipo` AS `tipo`,`t`.`nombre` AS `tamanio`,`t`.`capacidad` AS `capacidad`,`c`.`precio_venta` AS `precio_venta`,`c`.`estatus` AS `estatus`,group_concat(`p`.`nombre` order by `cp`.`cantidad` DESC separator ' + ') AS `productos`,sum(`cp`.`cantidad`) AS `total_piezas` from (((`cajas` `c` join `tamanios_charola` `t` on((`t`.`id_tamanio` = `c`.`id_tamanio`))) join `caja_productos` `cp` on((`cp`.`id_caja` = `c`.`id_caja`))) join `productos` `p` on((`p`.`id_producto` = `cp`.`id_producto`))) group by `c`.`id_caja`,`c`.`nombre`,`c`.`tipo`,`t`.`nombre`,`t`.`capacidad`,`c`.`precio_venta`,`c`.`estatus` */;
/*!50001 SET character_set_client      = @saved_cs_client */;
/*!50001 SET character_set_results     = @saved_cs_results */;
/*!50001 SET collation_connection      = @saved_col_connection */;

--
-- Final view structure for view `v_conteo_pedidos_por_estado`
--

/*!50001 DROP VIEW IF EXISTS `v_conteo_pedidos_por_estado`*/;
/*!50001 SET @saved_cs_client          = @@character_set_client */;
/*!50001 SET @saved_cs_results         = @@character_set_results */;
/*!50001 SET @saved_col_connection     = @@collation_connection */;
/*!50001 SET character_set_client      = utf8mb4 */;
/*!50001 SET character_set_results     = utf8mb4 */;
/*!50001 SET collation_connection      = utf8mb4_0900_ai_ci */;
/*!50001 CREATE ALGORITHM=UNDEFINED */
/*!50013 DEFINER=`root`@`localhost` SQL SECURITY DEFINER */
/*!50001 VIEW `v_conteo_pedidos_por_estado` AS select (convert(`pedidos`.`estado` using utf8mb4) collate utf8mb4_unicode_ci) AS `estado`,count(0) AS `total` from `pedidos` group by `pedidos`.`estado` */;
/*!50001 SET character_set_client      = @saved_cs_client */;
/*!50001 SET character_set_results     = @saved_cs_results */;
/*!50001 SET collation_connection      = @saved_col_connection */;

--
-- Final view structure for view `v_detalle_pedido`
--

/*!50001 DROP VIEW IF EXISTS `v_detalle_pedido`*/;
/*!50001 SET @saved_cs_client          = @@character_set_client */;
/*!50001 SET @saved_cs_results         = @@character_set_results */;
/*!50001 SET @saved_col_connection     = @@collation_connection */;
/*!50001 SET character_set_client      = utf8mb4 */;
/*!50001 SET character_set_results     = utf8mb4 */;
/*!50001 SET collation_connection      = utf8mb4_0900_ai_ci */;
/*!50001 CREATE ALGORITHM=UNDEFINED */
/*!50013 DEFINER=`root`@`localhost` SQL SECURITY DEFINER */
/*!50001 VIEW `v_detalle_pedido` AS select `dp`.`id_pedido` AS `id_pedido`,`pr`.`nombre` AS `producto_nombre`,`pr`.`descripcion` AS `producto_descripcion`,`dp`.`cantidad` AS `cantidad`,`dp`.`precio_unitario` AS `precio_unitario`,`dp`.`subtotal` AS `subtotal` from (`detalle_pedidos` `dp` join `productos` `pr` on((`pr`.`id_producto` = `dp`.`id_producto`))) */;
/*!50001 SET character_set_client      = @saved_cs_client */;
/*!50001 SET character_set_results     = @saved_cs_results */;
/*!50001 SET collation_connection      = @saved_col_connection */;

--
-- Final view structure for view `v_historial_pedido`
--

/*!50001 DROP VIEW IF EXISTS `v_historial_pedido`*/;
/*!50001 SET @saved_cs_client          = @@character_set_client */;
/*!50001 SET @saved_cs_results         = @@character_set_results */;
/*!50001 SET @saved_col_connection     = @@collation_connection */;
/*!50001 SET character_set_client      = utf8mb4 */;
/*!50001 SET character_set_results     = utf8mb4 */;
/*!50001 SET collation_connection      = utf8mb4_0900_ai_ci */;
/*!50001 CREATE ALGORITHM=UNDEFINED */
/*!50013 DEFINER=`root`@`localhost` SQL SECURITY DEFINER */
/*!50001 VIEW `v_historial_pedido` AS select `h`.`id_pedido` AS `id_pedido`,`h`.`estado_antes` AS `estado_antes`,`h`.`estado_despues` AS `estado_despues`,`h`.`nota` AS `nota`,`h`.`creado_en` AS `creado_en`,`u`.`nombre_completo` AS `usuario_nombre` from (`historial_pedidos` `h` left join `usuarios` `u` on((`u`.`id_usuario` = `h`.`realizado_por`))) */;
/*!50001 SET character_set_client      = @saved_cs_client */;
/*!50001 SET character_set_results     = @saved_cs_results */;
/*!50001 SET collation_connection      = @saved_col_connection */;

--
-- Final view structure for view `v_notificaciones_cliente`
--

/*!50001 DROP VIEW IF EXISTS `v_notificaciones_cliente`*/;
/*!50001 SET @saved_cs_client          = @@character_set_client */;
/*!50001 SET @saved_cs_results         = @@character_set_results */;
/*!50001 SET @saved_col_connection     = @@collation_connection */;
/*!50001 SET character_set_client      = utf8mb4 */;
/*!50001 SET character_set_results     = utf8mb4 */;
/*!50001 SET collation_connection      = utf8mb4_0900_ai_ci */;
/*!50001 CREATE ALGORITHM=UNDEFINED */
/*!50013 DEFINER=`root`@`localhost` SQL SECURITY DEFINER */
/*!50001 VIEW `v_notificaciones_cliente` AS select `notificaciones_pedidos`.`id_notif` AS `id_notif`,`notificaciones_pedidos`.`id_pedido` AS `id_pedido`,`notificaciones_pedidos`.`id_usuario` AS `id_usuario`,`notificaciones_pedidos`.`folio` AS `folio`,`notificaciones_pedidos`.`mensaje` AS `mensaje`,`notificaciones_pedidos`.`leida` AS `leida`,`notificaciones_pedidos`.`creado_en` AS `creado_en` from `notificaciones_pedidos` order by `notificaciones_pedidos`.`creado_en` desc */;
/*!50001 SET character_set_client      = @saved_cs_client */;
/*!50001 SET character_set_results     = @saved_cs_results */;
/*!50001 SET collation_connection      = @saved_col_connection */;

--
-- Final view structure for view `v_pedido_detalle_completo`
--

/*!50001 DROP VIEW IF EXISTS `v_pedido_detalle_completo`*/;
/*!50001 SET @saved_cs_client          = @@character_set_client */;
/*!50001 SET @saved_cs_results         = @@character_set_results */;
/*!50001 SET @saved_col_connection     = @@collation_connection */;
/*!50001 SET character_set_client      = utf8mb4 */;
/*!50001 SET character_set_results     = utf8mb4 */;
/*!50001 SET collation_connection      = utf8mb4_0900_ai_ci */;
/*!50001 CREATE ALGORITHM=UNDEFINED */
/*!50013 DEFINER=`root`@`localhost` SQL SECURITY DEFINER */
/*!50001 VIEW `v_pedido_detalle_completo` AS select `dp`.`id_pedido` AS `id_pedido`,`dp`.`id_detalle` AS `id_detalle`,(convert(`pr`.`nombre` using utf8mb4) collate utf8mb4_0900_ai_ci) AS `producto_nombre`,(convert(`pr`.`descripcion` using utf8mb4) collate utf8mb4_0900_ai_ci) AS `producto_descripcion`,`dp`.`cantidad` AS `cantidad`,`dp`.`precio_unitario` AS `precio_unitario`,`dp`.`subtotal` AS `subtotal` from (`detalle_pedidos` `dp` join `productos` `pr` on((`pr`.`id_producto` = `dp`.`id_producto`))) */;
/*!50001 SET character_set_client      = @saved_cs_client */;
/*!50001 SET character_set_results     = @saved_cs_results */;
/*!50001 SET collation_connection      = @saved_col_connection */;

--
-- Final view structure for view `v_pedidos_resumen`
--

/*!50001 DROP VIEW IF EXISTS `v_pedidos_resumen`*/;
/*!50001 SET @saved_cs_client          = @@character_set_client */;
/*!50001 SET @saved_cs_results         = @@character_set_results */;
/*!50001 SET @saved_col_connection     = @@collation_connection */;
/*!50001 SET character_set_client      = utf8mb4 */;
/*!50001 SET character_set_results     = utf8mb4 */;
/*!50001 SET collation_connection      = utf8mb4_0900_ai_ci */;
/*!50001 CREATE ALGORITHM=UNDEFINED */
/*!50013 DEFINER=`root`@`localhost` SQL SECURITY DEFINER */
/*!50001 VIEW `v_pedidos_resumen` AS select `p`.`id_pedido` AS `id_pedido`,`p`.`folio` AS `folio`,`p`.`estado` AS `estado`,`p`.`fecha_recogida` AS `fecha_recogida`,`p`.`total_estimado` AS `total_estimado`,`p`.`motivo_rechazo` AS `motivo_rechazo`,`p`.`creado_en` AS `creado_en`,`p`.`actualizado_en` AS `actualizado_en`,`p`.`id_cliente` AS `id_cliente`,`p`.`tipo` AS `tipo_caja`,(`t`.`nombre` collate utf8mb4_unicode_ci) AS `tamanio_nombre`,`t`.`capacidad` AS `capacidad`,`u`.`id_usuario` AS `id_usuario`,`u`.`nombre_completo` AS `cliente_nombre`,`u`.`username` AS `cliente_username`,count(`dp`.`id_detalle`) AS `num_productos`,ifnull(sum(`dp`.`cantidad`),0) AS `total_piezas`,`a`.`nombre_completo` AS `atendido_por_nombre` from ((((`pedidos` `p` join `usuarios` `u` on((`u`.`id_usuario` = `p`.`id_cliente`))) left join `tamanios_charola` `t` on((`t`.`id_tamanio` = `p`.`id_tamanio`))) left join `detalle_pedidos` `dp` on((`dp`.`id_pedido` = `p`.`id_pedido`))) left join `usuarios` `a` on((`a`.`id_usuario` = `p`.`atendido_por`))) group by `p`.`id_pedido`,`p`.`folio`,`p`.`estado`,`p`.`fecha_recogida`,`p`.`total_estimado`,`p`.`motivo_rechazo`,`p`.`creado_en`,`p`.`actualizado_en`,`p`.`id_cliente`,`p`.`tipo`,`t`.`nombre`,`t`.`capacidad`,`u`.`id_usuario`,`u`.`nombre_completo`,`u`.`username`,`a`.`nombre_completo` */;
/*!50001 SET character_set_client      = @saved_cs_client */;
/*!50001 SET character_set_results     = @saved_cs_results */;
/*!50001 SET collation_connection      = @saved_col_connection */;

--
-- Final view structure for view `v_recetas_explosion`
--

/*!50001 DROP VIEW IF EXISTS `v_recetas_explosion`*/;
/*!50001 SET @saved_cs_client          = @@character_set_client */;
/*!50001 SET @saved_cs_results         = @@character_set_results */;
/*!50001 SET @saved_col_connection     = @@collation_connection */;
/*!50001 SET character_set_client      = utf8mb4 */;
/*!50001 SET character_set_results     = utf8mb4 */;
/*!50001 SET collation_connection      = utf8mb4_0900_ai_ci */;
/*!50001 CREATE ALGORITHM=UNDEFINED */
/*!50013 DEFINER=`root`@`localhost` SQL SECURITY DEFINER */
/*!50001 VIEW `v_recetas_explosion` AS select `pt`.`nombre` AS `producto`,`r`.`nombre` AS `receta`,`r`.`rendimiento` AS `rendimiento`,`r`.`unidad_rendimiento` AS `unidad_rendimiento`,`mp`.`nombre` AS `insumo`,`dr`.`cantidad_requerida` AS `cantidad_requerida`,`mp`.`unidad_base` AS `unidad_base`,`dr`.`orden` AS `orden` from (((`detalle_recetas` `dr` join `recetas` `r` on((`r`.`id_receta` = `dr`.`id_receta`))) join `productos_terminados` `pt` on((`pt`.`id_producto` = `r`.`id_producto`))) join `materias_primas` `mp` on((`mp`.`id_materia` = `dr`.`id_materia`))) order by `pt`.`nombre`,`r`.`rendimiento`,`dr`.`orden` */;
/*!50001 SET character_set_client      = @saved_cs_client */;
/*!50001 SET character_set_results     = @saved_cs_results */;
/*!50001 SET collation_connection      = @saved_col_connection */;

--
-- Final view structure for view `v_recetas_por_tamanio`
--

/*!50001 DROP VIEW IF EXISTS `v_recetas_por_tamanio`*/;
/*!50001 SET @saved_cs_client          = @@character_set_client */;
/*!50001 SET @saved_cs_results         = @@character_set_results */;
/*!50001 SET @saved_col_connection     = @@collation_connection */;
/*!50001 SET character_set_client      = utf8mb4 */;
/*!50001 SET character_set_results     = utf8mb4 */;
/*!50001 SET collation_connection      = utf8mb4_0900_ai_ci */;
/*!50001 CREATE ALGORITHM=UNDEFINED */
/*!50013 DEFINER=`root`@`localhost` SQL SECURITY DEFINER */
/*!50001 VIEW `v_recetas_por_tamanio` AS select `r`.`id_receta` AS `id_receta`,`r`.`nombre` AS `nombre_receta`,`p`.`nombre` AS `nombre_producto`,`t`.`nombre` AS `tamanio`,`t`.`capacidad` AS `piezas`,`r`.`rendimiento` AS `rendimiento`,`mp`.`nombre` AS `ingrediente`,`dr`.`cantidad_requerida` AS `cantidad_requerida`,`mp`.`unidad_base` AS `unidad` from ((((`recetas` `r` join `tamanios_charola` `t` on((`t`.`id_tamanio` = `r`.`id_tamanio`))) join `productos` `p` on((`p`.`id_producto` = `r`.`id_producto`))) join `detalle_recetas` `dr` on((`dr`.`id_receta` = `r`.`id_receta`))) join `materias_primas` `mp` on((`mp`.`id_materia` = `dr`.`id_materia`))) where (`r`.`estatus` = 'activo') order by `p`.`nombre`,`t`.`capacidad`,`dr`.`orden` */;
/*!50001 SET character_set_client      = @saved_cs_client */;
/*!50001 SET character_set_results     = @saved_cs_results */;
/*!50001 SET collation_connection      = @saved_col_connection */;
/*!40103 SET TIME_ZONE=@OLD_TIME_ZONE */;

/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;

-- Dump completed on 2026-03-26 15:35:08
