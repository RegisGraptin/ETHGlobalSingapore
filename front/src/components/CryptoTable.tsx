import React, { useState } from "react";
import Chart from "react-apexcharts";
 
// @material-tailwind/react
import {
  Card,
  Menu,
  Input,
  Button,
  MenuList,
  MenuItem,
  CardBody,
  Typography,
  CardHeader,
  IconButton,
  MenuHandler,
  TypographyProps,
} from "@material-tailwind/react";
 
import {
    DocumentMagnifyingGlassIcon,
    MagnifyingGlassIcon,
    PaperAirplaneIcon
} from "@heroicons/react/24/solid";
import { ChevronDownIcon } from "@heroicons/react/24/outline";
 
// deepmerge
import merge from "deepmerge";
 
// area chart
interface ChartsPropsType {
  height: number;
  series: object[];
  options: object;
}
 
function AreaChart({
  height = 90,
  series,
  colors,
  options,
}: Partial<ChartsPropsType> & {
  colors: string | string[];
}) {
  const chartOptions = React.useMemo(
    () => ({
      colors,
      ...merge(
        {
          chart: {
            height: height,
            type: "area",
            zoom: {
              enabled: false,
            },
            toolbar: {
              show: false,
            },
          },
          title: {
            show: "",
          },
          dataLabels: {
            enabled: false,
          },
          legend: {
            show: false,
          },
          markers: {
            size: 0,
            strokeWidth: 0,
            strokeColors: "transparent",
          },
          stroke: {
            curve: "smooth",
            width: 2,
          },
          grid: {
            show: false,
            xaxis: {
              lines: {
                show: false,
              },
            },
            padding: {
              top: 0,
              right: 0,
              left: 0,
              bottom: 0,
            },
          },
          tooltip: {
            theme: "light",
          },
          yaxis: {
            labels: {
              show: false,
            },
          },
          xaxis: {
            axisTicks: {
              show: false,
            },
            axisBorder: {
              show: false,
            },
            labels: {
              show: false,
            },
          },
          fill: {
            type: "gradient",
            gradient: {
              shadeIntensity: 1,
              opacityFrom: 0.4,
              opacityTo: 0.6,
              stops: [0, 100],
            },
          },
        },
        options ? options : {},
      ),
    }),
    [height, colors, options],
  );
 
  return (
    <Chart
      type="area"
      height={height}
      series={series as ApexAxisChartSeries}
      options={chartOptions as any}
    />
  );
}
 
const TABLE_ROW = [
  {
    img: "https://www.material-tailwind.com/logos/btc.png",
    digitalAsset: "BTC",
    detail: "Bitcoin",
    price: "$63,151.10",
    change: "+0.09%",
    volume: "$45.31B",
    market: "$915.61B",
    color: "green",
    trend: 4,
  },
  {
    img: "https://www.material-tailwind.com/logos/eth.png",
    digitalAsset: "ETH",
    detail: "Ethereum",
    price: "$2,357.76",
    change: "+0.20%",
    volume: "$23.42B",
    market: "$313.58B",
    color: "green",
  },
  {
    img: "https://www.material-tailwind.com/logos/usdt.png",
    digitalAsset: "USDT",
    detail: "TetherUS",
    price: "$1.00",
    change: "-0.01%",
    volume: "$94.37B",
    market: "$40,600",
    color: "red",
  },
];
 
const TABLE_HEAD = [
  {
    head: "Digital Asset",
    customeStyle: "!text-left",
  },
  {
    head: "Price",
    customeStyle: "text-right",
  },
  {
    head: "Change",
    customeStyle: "text-right",
  },
  {
    head: "Trend",
    customeStyle: "text-right",
  },
  {
    head: "Actions",
    customeStyle: "text-right",
  },
];
 
export function CryptoTable() {

  const [selectedChain, setSelectedChain] = useState("");
  
  const [receiver, setReceiver] = useState("");
  const [amount, setAmount] = useState("");
  
  const [loading, setLoading] = useState(false);



  function chainAction(chain) {
    setSelectedChain(chain);
  }

  function transfer() {
    console.log("ok")
  }

  return (
    <>
    
    <Card className="h-full w-full">
      <CardHeader
        floated={false}
        shadow={false}
        className="mb-4 flex flex-wrap justify-between gap-4 rounded-none"
      >
        <div>
          <Typography variant="h6" color="blue-gray">
            Portfolio Overview
          </Typography>
          <Typography
            variant="small"
            className="mt-1 font-normal text-gray-600"
          >
            Manage your portfolio, and make informed investment.
          </Typography>
        </div>
        <div className="flex w-full shrink-0 items-center gap-4 md:w-max">
          <div className="w-full md:w-72">
            <Input
              size="lg"
              label="Search"
              icon={<MagnifyingGlassIcon className="h-5 w-5" />}
            />
          </div>
          <Menu>
            <MenuHandler>
              <Button
                variant="outlined"
                className="flex items-center gap-2 border-gray-300"
              >
                 24h
                <ChevronDownIcon strokeWidth={3} className="w-3 h-3" />
              </Button>
            </MenuHandler>
            <MenuList>
              <MenuItem>24h</MenuItem>
            </MenuList>
          </Menu>
        </div>
      </CardHeader>
      <CardBody className="overflow-scroll !px-0 py-2">
        <table className="w-full min-w-max table-auto">
          <thead>
            <tr>
              {TABLE_HEAD.map(({ head, customeStyle }) => (
                <th
                  key={head}
                  className={`border-b border-gray-300 !p-4 pb-8 ${customeStyle}`}
                >
                  <Typography
                    color="blue-gray"
                    variant="small"
                    className="!font-bold"
                  >
                    {head}
                  </Typography>
                </th>
              ))}
            </tr>
          </thead>
          <tbody>
            {TABLE_ROW.map(
              (
                {
                  img,
                  digitalAsset,
                  detail,
                  price,
                  change,
                  color,
                },
                index,
              ) => {
                const isLast = index === TABLE_ROW.length - 1;
                const classes = isLast
                  ? "!p-4"
                  : "!p-4 border-b border-gray-300";
                return (
                  <tr key={digitalAsset}>
                    <td className={classes}>
                      <div className="flex items-center gap-4 text-left">
                        <img
                          src={img}
                          alt={digitalAsset}
                          className="h-10 w-10"
                        />
                        <div>
                          <Typography
                            variant="small"
                            color="blue-gray"
                            className="!font-semibold"
                          >
                            {digitalAsset}
                          </Typography>
                          <Typography
                            variant="small"
                            className="!font-normal text-gray-600"
                          >
                            {detail}
                          </Typography>
                        </div>
                      </div>
                    </td>
                    <td className={classes}>
                      <Typography
                        variant="small"
                        className="text-right !font-normal text-gray-600"
                      >
                        {price}
                      </Typography>
                    </td>
                    <td className={classes}>
                      <Typography
                        variant="small"
                        color={color as TypographyProps["color"]}
                        className="text-right !font-bold"
                      >
                        {change}
                      </Typography>
                    </td>
                    <td className={classes}>
                      <div className="ml-auto h-12 max-w-[12rem] -translate-y-6">
                        <AreaChart
                          colors={["#2196F373"]}
                          options={{}}
                          series={[
                            {
                              name: "2024 Sales",
                              data: [30, 40, 500, 420, 700, 350, 500, 330, 900],
                            },
                          ]}
                        />
                      </div>
                    </td>
                    <td className={classes}>
                      <div className="flex justify-end gap-4">
                        
                        <IconButton variant="text" size="sm" onClick={() => chainAction(digitalAsset)}>
                          <PaperAirplaneIcon className="h-5 w-5 text-gray-900" />
                        </IconButton>


                      </div>
                    </td>
                  </tr>
                );
              },
            )}
          </tbody>
        </table>
      </CardBody>
    </Card>

  {selectedChain &&
    <div className="pt-5 container mx-auto w-1/2">

      <h2 className="pb-3 mx-auto text-center">Transfert "{selectedChain}"</h2>

      
      <div className="row mb-3">
        <label className="col-sm-2 col-form-label col-form-label-sm">To:</label>
        <div className="col-sm-10">
          <input type="text" className="form-control form-control-sm" value={receiver} onChange={(e) => setReceiver(e.target.value)} disabled={loading} />
        </div>
      </div>
      <div className="row mb-3">
        <label className="col-sm-2 col-form-label col-form-label-sm">Amount:</label>
        <div className="col-sm-10">
          <input type="number" className="form-control form-control-sm" value={amount} onChange={(e) => setAmount(e.target.value)} step="0.0001" disabled={loading} />
        </div>
      </div>
      
      <div class="w-1/2 mx-auto flex justify-center items-center">
      <Button className="" onClick={() => transfer()}>
        Transfer
      </Button>
      </div>
      
    </div>

  }
</>

  );
}
 
export default CryptoTable;