<?php
namespace CDash;

use CDash\Singleton;

class Config extends Singleton
{
    private $_config;

    protected function __construct()
    {
        include 'config/config.php';
        include 'include/version.php';
        $this->_config = get_defined_vars();
    }

    public function get($name)
    {
        if (isset($this->_config[$name])) {
            return $this->_config[$name];
        }
    }

    public function set($name, $value)
    {
        $this->_config[$name] = $value;
    }

    /**
     * @param bool $use_localhost
     * @return string
     */
    public function getServer($use_localhost = false)
    {
        if ($use_localhost) {
            return 'localhost';
        }

        $server = $this->get('CDASH_SERVER_NAME');
        if (empty($server)) {
            if (isset($_SERVER['SERVER_NAME'])) {
                $server = $_SERVER['SERVER_NAME'];
            } else {
                $server = 'localhost';
            }
        }
        return $server;
    }

    /**
     * @return string
     */
    public function getProtocol()
    {
        $protocol = 'http';
        if ($this->get('CDASH_USE_HTTPS') ||
            (isset($_SERVER['SERVER_PORT']) && $_SERVER['SERVER_PORT'] == 443)) {
            $protocol = 'https';
        }
        return $protocol;
    }

    /**
     * @return string
     */
    public function getServerPort()
    {
        if (isset($_SERVER['SERVER_PORT'])
            && $_SERVER['SERVER_PORT'] != 80
            && $_SERVER['SERVER_PORT'] != 443) {
            return $_SERVER['SERVER_PORT'];
        }
    }

    public function getPath()
    {
        $path = $this->get('CDASH_CURL_LOCALHOST_PREFIX') ?: $_SERVER['REQUEST_URI'];
        if (strpos($path, '/') !== 0) {
            $path = "/{$path}";
        }
        return $path;
    }


    /**
     * @param bool $use_localhost
     * @return string
     */
    public function getBaseUrl($use_localhost = false)
    {
        $uri = $this->get('CDASH_BASE_URL');

        if (!$uri) {
            $protocol = $this->getProtocol();
            $host = $this->getServer($use_localhost);
            $port = $this->getServerPort() ? ":{$this->getServerPort()}" : '';
            $path = $this->getPath();

            $uri = "{$protocol}://{$host}{$port}{$path}";
        }
        // strip trailing slash
        if (strrpos($uri, '/') === 0) {
            $uri = substr($uri, 0, (strlen($uri) - 1));
        }

        return $uri;
    }

    public function load($config)
    {
        return include "config/{$config}.php";
    }
}
